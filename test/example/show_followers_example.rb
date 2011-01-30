# coding: utf-8

require "example_helper"

Feature "show followers" do
  as_a "authenticated user"
  i_want_to "see my followers"
  in_order_to "to see who follows me"

  Scenario "show followers" do
    When "I start the application with 'followers' command" do
      stub_http_request(:get, "https://api.twitter.com/1/statuses/followers.json?count=20&page=1").to_return(:body => fixture_file('users.json'))
      @output = start_cli %w{followers}
    end

    Then "the application shows followers and their latest tweets (if any)" do
      @output[0].should == "jillv, 12 hours ago:"
      @output[1].should == "choosing next target"
      @output[2].should == ""
      @output[3].should == "ham"
      @output[4].should == nil
    end
  end
end
