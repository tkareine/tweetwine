require File.dirname(__FILE__) << "/../lib/tweetwine"

include Tweetwine

describe Application do
  before(:each) do
    @app = Application.new("foo", "bar")
  end

  xit "should show friend's timeline" do
    # TODO: mock
    #statuses = @app.friends_timeline
  end
end