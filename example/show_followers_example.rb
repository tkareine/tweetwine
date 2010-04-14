# coding: utf-8

require "example_helper"

FakeWeb.register_uri(:get, "https://#{TEST_AUTH}@twitter.com/statuses/followers/#{TEST_USER}.json", :body => fixture("users.json"))

Feature "show followers and their latest statuses" do
  in_order_to "to see who follows me"
  as_a "authenticated user"
  i_want_to "see my followers and their latest statuses, if any"

  Scenario "see followers and their latest statuses" do
    When "application is launched 'followers' command" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors followers})
    end

    Then "my followers and their latest statuses are shown" do
      @output[0].should == "jillv, 12 hours ago:"
      @output[1].should == "choosing next target"
      @output[2].should == ""
      @output[3].should == "ham"
      @output[4].should == nil
    end
  end
end
