require 'spec_helper'

BeforeSample = Struct.new(:title)

module BeforeSamplePresenter
  extend SexyPresenter::Hooks

  before_render do
    @model = BeforeSample.new('before sample')
  end
end

describe "sexy_presenter/messages/before" do
  before do
    render
  end

  it "shows messages" do
    response.should match("before sample")
  end
end
