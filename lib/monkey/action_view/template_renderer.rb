# -*- encoding: utf-8 -*-
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


