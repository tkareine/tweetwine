# coding: utf-8

require 'integration/helper'

module Tweetwine::Test::Integration

class ShowMentionsTest < TestCase
  before do
    stub_http_request(:get, "https://api.twitter.com/1/statuses/mentions.json?count=20&page=1").to_return(:body => fixture_file('mentions.json'))
    @output = start_cli %w{mentions}
  end

  it "shows tweets mentioning me" do
    @output[0].must_equal "jillv, in reply to fooman, 3 days ago:"
    @output[1].must_equal "@fooman, did you see their eyes glow yellow after sunset?"
    @output[2].must_equal ""
    @output[3].must_equal "redfield, in reply to fooman, 5 days ago:"
    @output[4].must_equal "sometimes it is just best to run, just like @fooman"
  end
end

end
