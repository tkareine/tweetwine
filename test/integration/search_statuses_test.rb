# coding: utf-8

require 'integration/helper'

module Tweetwine::Test::Integration

class SearchStatusesTest < TestCase
  SEARCH_BASE_URL = "http://search.twitter.com/search.json"
  SEARCH_OR_URL   = "#{SEARCH_BASE_URL}?q=braid%20OR%20game&rpp=2&page=1"
  SEARCH_AND_URL  = "#{SEARCH_BASE_URL}?q=braid%20game&rpp=2&page=1"
  SEARCH_FIXTURE  = fixture_file 'search.json'

  before do
    stub_http_request(:get, SEARCH_AND_URL).to_return(:body => SEARCH_FIXTURE)
    stub_http_request(:get, SEARCH_OR_URL).to_return(:body => SEARCH_FIXTURE)
  end

  describe "search tweets matching all words" do
    before do
      at_snapshot do
        @output = start_cli %w{-n 2 search -a braid game}
      end
    end

    it "requests tweets matching all the words and shows them" do
      assert_requested(:get, SEARCH_AND_URL)
      must_output_tweets
    end
  end

  describe "search tweets matching any words" do
    before do
      at_snapshot do
        @output = start_cli %w{-n 2 search -o braid game}
      end
    end

    it "requests tweets matching any of the words and shows them" do
      assert_requested(:get, SEARCH_OR_URL)
      must_output_tweets
    end
  end

  describe "searching for all words is implied unless other is specified" do
    before do
      at_snapshot do
        @output = start_cli %w{-n 2 search braid game}
      end
    end

    it "requests tweets matching all the words and shows them" do
      assert_requested(:get, SEARCH_AND_URL)
      must_output_tweets
    end
  end

  describe "search without words" do
    before do
      @status = start_app %w{-n 2 search} do |_, _, _, stderr|
        @output = stderr.gets
      end
    end

    it "shows error message and exists with error status" do
      @output.must_equal "ERROR: No search words.\n"
      @status.exitstatus.must_equal CommandLineError.status_code
    end
  end

  private

  def must_output_tweets
    @output[0].must_equal "thatswhatshesaid, in reply to hatguy, 5 hours ago:"
    @output[1].must_equal "@hatguy braid, perhaps the best indie game of 2009"
    @output[2].must_equal ""
    @output[3].must_equal "jillv, 11 hours ago:"
    @output[4].must_equal "braid is even better than of the games i'm in, expect re4"
  end
end

end
