# coding: utf-8

require 'support/integration_test_case'

module Tweetwine::Test::Integration

class GlobalOptionsTest < TestCase
  before do
    stub_http_request(:get, %r{https://api.twitter.com/1/statuses/home_timeline\.json\?count=\d+&page=\d+}).to_return(:body => fixture_file('home.json'))
  end

  describe "colors" do
    before do
      at_snapshot do
        @output = start_cli %w{--colors}
      end
    end

    it "shows tweets with colors" do
      @output[0].must_equal "\e[32mpelit\e[0m, 11 days ago:"
      @output[1].must_equal "F1-kausi alkaa marraskuussa \e[36mhttp://bit.ly/1qQwjQ\e[0m"
      @output[2].must_equal ""
      @output[58].must_equal "\e[32mradar\e[0m, 15 days ago:"
      @output[59].must_equal "Four short links: 29 September 2009 \e[36mhttp://bit.ly/dYxay\e[0m"
    end
  end

  describe "show reverse" do
    before do
      at_snapshot do
        @output = start_cli %w{--reverse}
      end
    end

    it "shows tweets in reverse order" do
      @output[0].must_equal "radar, 15 days ago:"
      @output[1].must_equal "Four short links: 29 September 2009 http://bit.ly/dYxay"
      @output[2].must_equal ""
      @output[58].must_equal "pelit, 11 days ago:"
      @output[59].must_equal "F1-kausi alkaa marraskuussa http://bit.ly/1qQwjQ"
    end
  end

  describe "num" do
    before do
      @num = 2
      @output = start_cli %W{--num #{@num}}
    end

    it "requests the specified number of tweets" do
      assert_requested(:get, %r{/home_timeline\.json\?count=#{@num}&page=\d+})
    end
  end

  describe "page" do
    before do
      @page = 2
      @output = start_cli %W{--page #{@page}}
    end

    it "requests the specified page number for tweets" do
      assert_requested(:get, %r{/home_timeline\.json\?count=\d+&page=#{@page}})
    end
  end
end

end
