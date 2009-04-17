require File.dirname(__FILE__) << "/spec_helper"

include Tweetwine

describe Client do
  before(:each) do
    @client = Client.new("foo", "bar")
  end

  xit "should show friend's timeline" do
    # TODO: mock response
    #statuses = @client.friends
  end
end