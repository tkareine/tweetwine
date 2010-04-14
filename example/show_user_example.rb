# coding: utf-8

require "example_helper"

FakeWeb.register_uri(:get, "https://#{TEST_AUTH}@twitter.com/statuses/user_timeline/#{TEST_USER}.json?count=20&page=1", :body => fixture("user.json"))

Feature "show a specific user's latest statuses" do
  in_order_to "to see what is going on with a specific user"
  as_a "authenticated user"
  i_want_to "see the latest statuses of a specific user"

  Scenario "see my latest statuses" do
    When "application is launched 'user' command and without extra arguments" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors user})
    end

    Then "my the latest statuses are shown" do
      @output[0].should == "jillv, in reply to chris, 9 hours ago:"
      @output[1].should == "@chris wait me until the garden"
      @output[2].should == ""
      @output[3].should == "jillv, 3 days ago:"
      @output[4].should == "so boring to wait"
    end
  end

  Scenario "see the latest statuses of another user" do
    When "application is launched 'user' command and the user as an extra argument" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors user #{TEST_USER}})
    end

    Then "the latest statuses of the user are shown" do
      @output[0].should == "jillv, in reply to chris, 9 hours ago:"
      @output[1].should == "@chris wait me until the garden"
      @output[2].should == ""
      @output[3].should == "jillv, 3 days ago:"
      @output[4].should == "so boring to wait"
    end
  end
end
