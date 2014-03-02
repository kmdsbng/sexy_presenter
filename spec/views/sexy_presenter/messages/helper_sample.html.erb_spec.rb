require 'spec_helper'

module HelperSamplePresenter

  refine ActionView::Base do
    def appended_helper
      'appended helper'
    end
  end
end

describe "sexy_presenter/messages/helper_sample" do
  before do
    render
  end

  it "shows messages" do
    response.should match("appended helper")
  end
end
