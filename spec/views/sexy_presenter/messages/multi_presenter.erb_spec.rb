require 'spec_helper'

Post = Struct.new(:body, :comments)
Comment = Struct.new(:body)

module PostSummaryPresenter
  extend SexyPresenter::Hooks

  before_render do
    @post_summary_presenter_str = 'post_summary_presenter_before_render'
  end

  refine Post do
    def summary
      self.body[0..5] + '...'
    end
  end
end

module CommentSummaryPresenter
  extend SexyPresenter::Hooks

  before_render do
    @comment_summary_presenter_str = 'comment_summary_presenter_before_render'
  end

  refine Comment do
    def summary
      self.body[0..5] + '...'
    end
  end
end

describe "sexy_presenter/messages/multi_presenter" do
  before do
    comments = [
      Comment.new('foofoo'),
      Comment.new('barbar'),
      Comment.new('bazbaz'),
    ]
    @post = Post.new('hogehoge', comments)
    render
  end

  it "shows refined post message" do
    response.should match("hogeh...")
  end

  it "shows refined comment message" do
    response.should match("foofo...")
  end

  it "runs multi presenter before_render" do
    response.should match("post_summary_presenter_before_render")
    response.should match("comment_summary_presenter_before_render")
  end

end
