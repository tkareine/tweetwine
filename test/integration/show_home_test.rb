# coding: utf-8

require 'support/integration_test_case'

module Tweetwine::Test::Integration

class ShowHomeTest < TestCase
  before do
    stub_http_request(:get, "https://api.twitter.com/1/statuses/home_timeline.json?count=20&page=1").to_return(:body => fixture_file('home.json'))
  end

  describe "show home timeline" do
    before do
      at_snapshot do
        @output = start_cli %w{--no-colors home}
      end
    end

    it "shows tweets from home timeline" do
      must_output_tweets
    end
  end

  describe "show home timeline is default command" do
    before do
      at_snapshot do
        @output = start_cli %w{--no-colors}
      end
    end

    it "shows tweets from home timeline" do
      must_output_tweets
    end
  end

  private

  def must_output_tweets
    @output[0].must_equal "pelit, 11 days ago:"
    @output[1].must_equal "F1-kausi alkaa marraskuussa http://bit.ly/1qQwjQ"
    @output[2].must_equal ""
    @output[58].must_equal "radar, 15 days ago:"
    @output[59].must_equal "Four short links: 29 September 2009 http://bit.ly/dYxay"
  end
end

end
