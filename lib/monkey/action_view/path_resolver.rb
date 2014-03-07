# -*- encoding: utf-8 -*-
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
        if yaml.kind_of?(Hash) && (presenter_module_name = yaml['presenter']).present?
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
    # presenter: PostShowTemplate
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

