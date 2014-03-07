# -*- encoding: utf-8 -*-
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




