require 'spec_helper'

Message = Struct.new(:title, :body)

module MessagePresenter
  refine Message do
    def body_length
      self.body.length
    end
  end
end

describe "sexy_presenter/messages/index" do
  before do
    @messages = [
      Message.new('A', 'aaa'),
      Message.new('B', 'bbb'),
    ]
    render
  end

  it "shows messages" do
    response.should match("A,aaa,3\nB,bbb,3")
  end
end
