# coding: utf-8

require "example_helper"

Feature "show friends" do
  in_order_to "to see who I follow"
  as_a "authenticated user"
  i_want_to "see my friends"

  Scenario "show friends" do
    When "I start the application with 'followers' command" do
      stub_http_request "https://api.twitter.com/1/statuses/friends.json?count=20&page=1", :body => fixture("users.json")
      @output = start_cli %w{friends}
    end

    Then "the application shows friends and their latest tweets (if any)" do
      @output[0].should == "jillv, 12 hours ago:"
      @output[1].should == "choosing next target"
      @output[2].should == ""
      @output[3].should == "ham"
      @output[4].should == nil
    end
  end
end
