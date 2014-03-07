# -*- encoding: utf-8 -*-
module SexyPresenter
  module Hooks
    def before_render(&block)
      @__before_render = block
    end
  end
end



