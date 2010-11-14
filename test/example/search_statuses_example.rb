# coding: utf-8

require "example_helper"

Feature "search tweets" do
  in_order_to "search statuses"
  as_a "authenticated user"
  i_want_to "see tweets matching the search"

  SEARCH_OR_URL = "http://search.twitter.com/search.json?q=braid%20game&rpp=2&page=1"
  SEARCH_AND_URL = "http://search.twitter.com/search.json?q=braid%20OR%20game&rpp=2&page=1"
  SEARCH_FIXTURE = fixture("search.json")

  Scenario "search words" do
    When "I start the application with command 'search' and search words" do
      stub_http_request(:get, SEARCH_OR_URL).to_return(:body => SEARCH_FIXTURE)
      @output = start_cli %w{-n 2 search braid game}
    end

    Then "the application shows tweets matching all the words" do
      @output[0].should == "thatswhatshesaid, in reply to hatguy, 5 hours ago:"
      @output[1].should == "@hatguy braid, perhaps the best indie game of 2009"
      @output[2].should == ""
      @output[3].should == "jillv, 11 hours ago:"
      @output[4].should == "braid is even better than of the games i'm in, expect re4"
    end
  end

  Scenario "search tweets matching all words" do
    When "I start the application with command 'search', option '-a', and search words" do
      stub_http_request(:get, SEARCH_OR_URL).to_return(:body => SEARCH_FIXTURE)
      @output = start_cli %w{-n 2 search -a braid game}
    end

    Then "the application shows tweets matching all the words" do
      @output[0].should == "thatswhatshesaid, in reply to hatguy, 5 hours ago:"
      @output[1].should == "@hatguy braid, perhaps the best indie game of 2009"
      @output[2].should == ""
      @output[3].should == "jillv, 11 hours ago:"
      @output[4].should == "braid is even better than of the games i'm in, expect re4"
    end
  end

  Scenario "search tweets matching any words" do
    When "I start the application with command 'search', option '-o', and search words" do
      stub_http_request(:get, SEARCH_AND_URL).to_return(:body => SEARCH_FIXTURE)
      @output = start_cli %w{-n 2 search -o braid game}
    end

    Then "the application shows tweets matching any of the words" do
      @output[0].should == "thatswhatshesaid, in reply to hatguy, 5 hours ago:"
      @output[1].should == "@hatguy braid, perhaps the best indie game of 2009"
      @output[2].should == ""
      @output[3].should == "jillv, 11 hours ago:"
      @output[4].should == "braid is even better than of the games i'm in, expect re4"
    end
  end

  Scenario "search without words" do
    When "I start the application with 'search' command without search words" do
      @status = start_app %w{-n 2 search} do |_, _, _, stderr|
        @output = stderr.gets
      end
    end

    Then "the application shows error message and exists with error status" do
      @output.should == "ERROR: No search words.\n"
      @status.exitstatus.should == CommandLineError.status_code
    end
  end
end
