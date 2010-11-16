# coding: utf-8

require "example_helper"

Feature "show tweets mentioning the user" do
  in_order_to "know if someone has mentioned me"
  as_a "authenticated user"
  i_want_to "see the tweets mentioning me"

  Scenario "show tweets mentioning me" do
    When "I start the application with 'mentions' command" do
      stub_http_request(:get, "https://api.twitter.com/1/statuses/mentions.json?count=20&page=1").to_return(:body => fixture_file('mentions.json'))
      @output = start_cli %w{mentions}
    end

    Then "the application shows tweets mentioning me" do
      @output[0].should == "jillv, in reply to fooman, 3 days ago:"
      @output[1].should == "@fooman, did you see their eyes glow yellow after sunset?"
      @output[2].should == ""
      @output[3].should == "redfield, in reply to fooman, 5 days ago:"
      @output[4].should == "sometimes it is just best to run, just like @fooman"
    end
  end
end
