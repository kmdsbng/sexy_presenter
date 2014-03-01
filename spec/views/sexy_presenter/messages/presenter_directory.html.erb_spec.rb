require 'spec_helper'

class Hoge
end

describe "sexy_presenter/messages/presenter_directory" do
  before do
    @hoge = Hoge.new
    render
  end

  it "shows messages" do
    response.should match("moge")
  end
end
