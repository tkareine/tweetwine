# coding: utf-8

require "example_helper"

Feature "global options" do
  as_a "user"
  i_want_to "set global options"
  in_order_to "affect general application behavior"

  def setup
    super
    stub_http_request(:get, %r{https://api.twitter.com/1/statuses/home_timeline\.json\?count=\d+&page=\d+}).to_return(:body => fixture_file('home.json'))
  end

  Scenario "colors" do
    When "I start the application with '--colors' option" do
      @output = start_cli %w{--colors}
    end

    Then "the application shows tweets with colors" do
      @output[0].should  == "\e[32mpelit\e[0m, 11 days ago:"
      @output[1].should  == "F1-kausi alkaa marraskuussa \e[36mhttp://bit.ly/1qQwjQ\e[0m"
      @output[2].should  == ""
      @output[58].should == "\e[32mradar\e[0m, 15 days ago:"
      @output[59].should == "Four short links: 29 September 2009 \e[36mhttp://bit.ly/dYxay\e[0m"
    end
  end

  Scenario "show reverse" do
    When "I start the application with '--reverse' option" do
      @output = start_cli %w{--reverse}
    end

    Then "the application shows tweets in reverse order" do
      @output[0].should  == "radar, 15 days ago:"
      @output[1].should  == "Four short links: 29 September 2009 http://bit.ly/dYxay"
      @output[2].should  == ""
      @output[58].should == "pelit, 11 days ago:"
      @output[59].should == "F1-kausi alkaa marraskuussa http://bit.ly/1qQwjQ"
    end
  end

  Scenario "num" do
    When "I start the application with '--num <n>' option" do
      @num = 2
      @output = start_cli %W{--num #{@num}}
    end

    Then "the application requests the specified number of tweets" do
      assert_requested(:get, %r{/home_timeline\.json\?count=#{@num}&page=\d+})
    end
  end

  Scenario "page" do
    When "I start the application with '--page <p>' option" do
      @page = 2
      @output = start_cli %W{--page #{@page}}
    end

    Then "the application requests the specified page number for tweets" do
      assert_requested(:get, %r{/home_timeline\.json\?count=\d+&page=#{@page}})
    end
  end
end
