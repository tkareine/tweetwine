# coding: utf-8

require "example_helper"

Feature "show tweets from home timeline" do
  in_order_to "stay up-to-date of other people's doings"
  as_a "authenticated user"
  i_want_to "see my home timeline"

  def setup
    super
    stub_http_request "https://api.twitter.com/1/statuses/home_timeline.json?count=20&page=1", :body => fixture("home.json")
  end

  Scenario "with colorization disabled" do
    When "I start the application with no command" do
      @output = start_cli %w{--no-colors}
    end

    Then "the application shows tweets from home timeline without colors" do
      @output[0].should == "pelit, 11 days ago:"
      @output[1].should == "F1-kausi alkaa marraskuussa http://bit.ly/1qQwjQ"
      @output[2].should == ""
      @output[58].should == "radar, 15 days ago:"
      @output[59].should == "Four short links: 29 September 2009 http://bit.ly/dYxay"
    end
  end

  Scenario "with colorization enabled" do
    When "I start the application with no command" do
      @output = start_cli %w{--colors}
    end

    Then "the application shows tweets from home timeline with colors" do
      @output[0].should == "\e[32mpelit\e[0m, 11 days ago:"
      @output[1].should == "F1-kausi alkaa marraskuussa \e[36mhttp://bit.ly/1qQwjQ\e[0m"
      @output[2].should == ""
      @output[58].should == "\e[32mradar\e[0m, 15 days ago:"
      @output[59].should == "Four short links: 29 September 2009 \e[36mhttp://bit.ly/dYxay\e[0m"
    end
  end

  Scenario "the command for showing the home view is the default command" do
    When "I start the application with 'home' command" do
      @output = start_cli %w{--no-colors home}
    end

    Then "the application shows tweets from home timeline" do
      @output[0].should == "pelit, 11 days ago:"
      @output[1].should == "F1-kausi alkaa marraskuussa http://bit.ly/1qQwjQ"
      @output[2].should == ""
      @output[58].should == "radar, 15 days ago:"
      @output[59].should == "Four short links: 29 September 2009 http://bit.ly/dYxay"
    end
  end
end
