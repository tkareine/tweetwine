require "example_helper"

FakeWeb.register_uri(:get, "http://search.twitter.com/search.json?q=braid%20game&rpp=2&page=1", :body => fixture("search.json"))

Feature "search statuses" do
  in_order_to "search statuses"
  as_a "any user"
  i_want_to "see latest statuses that match the search"

  Scenario "see statuses that match to the search" do
    When "application is launched 'search' command" do
      @output = launch_cli(%W{-a anyuser:anypwd --no-colors -n 2 search braid game})
    end

    Then "the latest statuses matching the search are shown" do
      @output[0].should == "thatswhatshesaid, in reply to hatguy, 5 hours ago:"
      @output[1].should == "@hatguy braid, perhaps the best indie game of 2009"
      @output[2].should == ""
      @output[3].should == "jillv, 11 hours ago:"
      @output[4].should == "braid is even better than of the games i'm in, expect re4"
    end
  end
end
