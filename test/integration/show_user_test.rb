# coding: utf-8

require 'integration/helper'

module Tweetwine::Test::Integration

class ShowUserTest < TestCase
  USER_URL = "https://api.twitter.com/1/statuses/user_timeline.json?count=20&page=1&screen_name=%s"
  USER_FIXTURE = fixture_file 'user.json'

  describe "show my tweets" do
    before do
      stub_http_request(:get, USER_URL % USER).to_return(:body => USER_FIXTURE)
      @output = start_cli %w{user}
    end

    it "shows my tweets" do
      must_output_tweets
    end
  end

  describe "show another user's tweets" do
    before do
      stub_http_request(:get, USER_URL % 'jillv').to_return(:body => USER_FIXTURE)
      @output = start_cli %w{user jillv}
    end

    it "shows the user's tweets" do
      must_output_tweets
    end
  end

  private

  def must_output_tweets
    @output[0].must_equal "jillv, in reply to chris, 9 hours ago:"
    @output[1].must_equal "@chris wait me until the garden"
    @output[2].must_equal ""
    @output[3].must_equal "jillv, 3 days ago:"
    @output[4].must_equal "so boring to wait"
  end
end

end
