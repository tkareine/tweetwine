# coding: utf-8

require "example_helper"

Feature "show tweets from home timeline" do
  as_a "authenticated user"
  i_want_to "see my home timeline"
  in_order_to "stay up-to-date of other people's doings"

  def setup
    super
    stub_http_request(:get, "https://api.twitter.com/1/statuses/home_timeline.json?count=20&page=1").to_return(:body => fixture_file('home.json'))
  end

  Scenario "show home timeline" do
    When "I start the application with 'home' command" do
      @output = start_cli %w{--no-colors home}
    end

    Then "the application shows tweets from home timeline" do
      should_output_tweets
    end
  end

  Scenario "show home timeline is default command" do
    When "I start the application with no command" do
      @output = start_cli %w{--no-colors}
    end

    Then "the application shows tweets from home timeline" do
      should_output_tweets
    end
  end

  private

  def should_output_tweets
    @output[0].should == "pelit, 11 days ago:"
    @output[1].should == "F1-kausi alkaa marraskuussa http://bit.ly/1qQwjQ"
    @output[2].should == ""
    @output[58].should == "radar, 15 days ago:"
    @output[59].should == "Four short links: 29 September 2009 http://bit.ly/dYxay"
  end
end
