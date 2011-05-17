# coding: utf-8

require 'integration/helper'

module Tweetwine::Test::Integration

class ShowFollowersTest < TestCase
  before do
    stub_http_request(:get, "https://api.twitter.com/1/statuses/followers.json?count=20&page=1").to_return(:body => fixture_file('users.json'))
    at_snapshot do
      @output = start_cli %w{followers}
    end
  end

  it "shows followers and their latest tweets (if any)" do
    @output[0].must_equal "jillv, 12 hours ago:"
    @output[1].must_equal "choosing next target"
    @output[2].must_equal ""
    @output[3].must_equal "ham"
    @output[4].must_equal nil
  end
end

end
