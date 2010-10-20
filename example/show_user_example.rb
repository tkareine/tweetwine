# coding: utf-8

require "example_helper"

Feature "show user's tweets" do
  in_order_to "to see what's going on with a specific user"
  as_a "authenticated user"
  i_want_to "see that user's tweets"

  Scenario "show my tweets" do
    When "I start the application with 'user' command without extra arguments" do
      stub_http_request(:get, "https://api.twitter.com/1/statuses/user_timeline.json?count=20&page=1&screen_name=#{USER}").to_return(:body => fixture("user.json"))
      @output = start_cli %w{user}
    end

    Then "the application shows my tweets" do
      @output[0].should == "jillv, in reply to chris, 9 hours ago:"
      @output[1].should == "@chris wait me until the garden"
      @output[2].should == ""
      @output[3].should == "jillv, 3 days ago:"
      @output[4].should == "so boring to wait"
    end
  end

  Scenario "show another user's tweets" do
    When "I start the application with 'user' command with the user as argument" do
      stub_http_request(:get, "https://api.twitter.com/1/statuses/user_timeline.json?count=20&page=1&screen_name=jillv").to_return(:body => fixture("user.json"))
      @output = start_cli %w{user jillv}
    end

    Then "the application shows the user's tweets" do
      @output[0].should == "jillv, in reply to chris, 9 hours ago:"
      @output[1].should == "@chris wait me until the garden"
      @output[2].should == ""
      @output[3].should == "jillv, 3 days ago:"
      @output[4].should == "so boring to wait"
    end
  end
end
