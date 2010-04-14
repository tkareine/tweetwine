# coding: utf-8

require "example_helper"

FakeWeb.register_uri(:get, "https://#{TEST_AUTH}@twitter.com/statuses/mentions.json?count=20&page=1", :body => fixture("mentions.json"))

Feature "show the latest statuses mentioning the user" do
  in_order_to "know if someone has mention me"
  as_a "authenticated user"
  i_want_to "see the latest statuses that mention me"

  Scenario "see the latest statuses that mention me" do
    When "application is launched with 'mentions' command" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors mentions})
    end

    Then "the latest statuses that mention me are shown" do
      @output[0].should == "jillv, in reply to fooman, 3 days ago:"
      @output[1].should == "@fooman, did you see their eyes glow yellow after sunset?"
      @output[2].should == ""
      @output[3].should == "redfield, in reply to fooman, 5 days ago:"
      @output[4].should == "sometimes it is just best to run, just like @fooman"
    end
  end
end
