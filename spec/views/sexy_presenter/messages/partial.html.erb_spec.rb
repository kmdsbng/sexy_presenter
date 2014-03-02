require 'spec_helper'

PartialModel = Struct.new(:title)

module PartialModelPresenter
  extend SexyPresenter::Hooks

  before_render do
    @partial_model = PartialModel.new('foo')
  end

  refine PartialModel do
    def appended_method
      "#{self.title} appended method"
    end
  end
end

describe "sexy_presenter/messages/partial" do
  #before do
  #  @partial_model = PartialModel.new('foo')
  #end

  it "shows messages" do
    render(:partial => 'partial_sample')
    #response.should render_template(:partial => 'partial_name')
    response.should match("foo appended method")
  end
end
