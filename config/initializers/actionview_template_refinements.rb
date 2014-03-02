# -*- encoding: utf-8 -*-

#TOPLEVEL_MAIN = self

#using PostShowRole

module ActionView
  # = Action View Template
  class Template

    protected
      # Among other things, this method is responsible for properly setting
      # the encoding of the compiled template.
      #
      # If the template engine handles encodings, we send the encoded
      # String to the engine without further processing. This allows
      # the template engine to support additional mechanisms for
      # specifying the encoding. For instance, ERB supports <%# encoding: %>
      #
      # Otherwise, after we figure out the correct encoding, we then
      # encode the source into <tt>Encoding.default_internal</tt>.
      # In general, this means that templates will be UTF-8 inside of Rails,
      # regardless of the original source encoding.
      def compile(view, mod) #:nodoc:
        encode!
        method_name = self.method_name
        code = @handler.call(self)

        # Make sure that the resulting String to be evalled is in the
        # encoding of the code
        source = <<-end_src
          def #{method_name}(local_assigns, output_buffer)
            _old_virtual_path, @virtual_path = @virtual_path, #{@virtual_path.inspect};_old_output_buffer = @output_buffer;#{locals_code};#{code}
          ensure
            @virtual_path, @output_buffer = _old_virtual_path, _old_output_buffer
          end
        end_src

        # Make sure the source is in the encoding of the returned code
        source.force_encoding(code.encoding)

        # In case we get back a String from a handler that is not in
        # BINARY or the default_internal, encode it to the default_internal
        source.encode!

        # Now, validate that the source we got back from the template
        # handler is valid in the default_internal. This is for handlers
        # that handle encoding but screw up
        unless source.valid_encoding?
          raise WrongEncodingError.new(@source, Encoding.default_internal)
        end

        begin
          # Replace eval to template_method
          #mod.module_eval(source, identifier, 0)
          eval_template_contents(mod, source)
          ObjectSpace.define_finalizer(self, Finalizer[method_name, mod])
        rescue Exception => e # errors from template code
          if logger = (view && view.logger)
            logger.debug "ERROR: compiling #{method_name} RAISED #{e}"
            logger.debug "Function body: #{source}"
            logger.debug "Backtrace: #{e.backtrace.join("\n")}"
          end

          raise ActionView::Template::Error.new(self, e)
        end
      end

      def eval_template_contents(mod, source)
        mod.module_eval(source, identifier, 0)
      end

  end
end


module ActionView
  # = Action View Resolver
  class PathResolver < Resolver #:nodoc:
    def query(path, details, formats)
      query = build_query(path, details)

      # deals with case-insensitive file systems.
      sanitizer = Hash.new { |h,dir| h[dir] = Dir["#{dir}/*"] }

      template_paths = Dir[query].reject { |filename|
        File.directory?(filename) ||
          !sanitizer[File.dirname(filename)].include?(filename)
      }

      template_paths.map { |template|
        handler, format = extract_handler_and_format(template, formats)
        contents = File.binread template

        contents, template_class = detect_template_class_in_contents(template, contents)

        template_class.new(contents, File.expand_path(template), handler,
          :virtual_path => path.virtual,
          :format       => format,
          :updated_at   => mtime(template))
      }
    end

    # This method create custom template class for using presenter module.
    def detect_template_class_in_contents(template_full_path, org_contents)
      frontmatter, contents = separate_frontmatter(org_contents)
      if frontmatter
        yaml = YAML.load(frontmatter)
        if yaml.kind_of?(Hash) && (presenter_module_name = yaml['using']).present?
          presenter_modules = Array(presenter_module_name).map(&:constantize)
          template_class_name = make_template_class_name(template_full_path, presenter_modules)
          unless Object.const_defined?(template_class_name)

            # Create custom template class
            #
            # This defines custom template class by eval, in top level, because use using method.
            # (Hack:
            #   using method could be used in eval. And in template that was module_evaled,
            #   refine in presenter_modules is effective.)
            eval("
            #{presenter_modules.map {|mod| "using #{mod.name}"}.join(';')}

            class #{template_class_name} < ActionView::Template
              @presenters = [#{presenter_modules.map {|mod| mod.name}.join(', ')}]
              def eval_template_contents(mod, source)
                mod.module_eval(source, identifier, #{frontmatter.each_line.to_a.size + 2})
              end
            end
            ", TOPLEVEL_BINDING)
          end

          # return custom template class
          return [contents, template_class_name.constantize]
        end
      end

      # default behavior
      [contents, Template]
    end

    def make_template_class_name(template_full_path, presenter_modules)
      'SexyPresenter_' +
        template_full_path.sub(Rails.root.to_s, '').gsub(/[\/\\\-\.]/, '_') +
        '_using_' +
        presenter_modules.map(&:name).join('_').gsub(/:/, '') +
        '_Template'
    end

    # separate view contents text in frontmatter and contents.
    #
    # example.html.slim
    # =======================================
    # ---
    # using: PostShowTemplate
    # ---
    #
    # h1 Example Page
    #
    # =======================================
    #
    # retval: [fronamatter, contents]
    def separate_frontmatter(contents)
      lines = contents.lines
      frontmatter_break_rows = lines.map.with_index {|line, i| (line.chomp == '---') ? i : nil}.compact
      frontmatter_start = frontmatter_break_rows[0]
      frontmatter_end   = frontmatter_break_rows[1]
      if frontmatter_start && frontmatter_start == 0 && frontmatter_end
        [lines[frontmatter_start+1...frontmatter_end].join,
         lines[frontmatter_end+1..-1].join]
      else
        [nil, contents]
      end
    end
  end
end

module ActionView
  class TemplateRenderer < AbstractRenderer #:nodoc:
    def render(context, options)
      @view    = context
      @details = extract_details(options)
      template = determine_template(options)
      context  = @lookup_context

      prepend_formats(template.formats)

      unless context.rendered_format
        context.rendered_format = template.formats.first || formats.first
      end

      # Process before_render hook
      if template.class.instance_variable_get(:@presenters)
        template.class.instance_variable_get(:@presenters).each {|presenter|
          if presenter.instance_variable_get(:@__before_render)
            @view.send('instance_eval', &presenter.instance_variable_get(:@__before_render))
          end
        }
      end
      render_template(template, options[:layout], options[:locals])
    end

  end
end

module ActionView
  class PartialRenderer < AbstractRenderer

    def render(context, options, block)
      setup(context, options, block)
      identifier = (@template = find_partial) ? @template.identifier : @path

      @lookup_context.rendered_format ||= begin
        if @template && @template.formats.present?
          @template.formats.first
        else
          formats.first
        end
      end

      # Process before_render hook
      if @template.class.instance_variable_get(:@presenters)
        @template.class.instance_variable_get(:@presenters).each {|presenter|
          if presenter.instance_variable_get(:@__before_render)
            @view.send('instance_eval', &presenter.instance_variable_get(:@__before_render))
          end
        }
      end

      if @collection
        instrument(:collection, :identifier => identifier || "collection", :count => @collection.size) do
          render_collection
        end
      else
        instrument(:partial, :identifier => identifier) do
          render_partial
        end
      end
    end
  end
end



