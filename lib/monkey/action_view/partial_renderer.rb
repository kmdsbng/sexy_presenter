# -*- encoding: utf-8 -*-
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



