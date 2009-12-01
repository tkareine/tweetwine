require "example_helper"

FakeWeb.register_uri(:get, "https://#{TEST_AUTH}@twitter.com/statuses/home_timeline.json?count=20&page=1", :body => fixture("home.json"))

Feature "show the latest statuses in the home timeline for the user" do
  in_order_to "stay up-to-date"
  as_a "authenticated user"
  i_want_to "see the latest statuses in the home view"

  Scenario "see home with colorization disabled" do
    When "application is launched with no command" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors})
    end

    Then "the latest statuses in the home view are shown" do
      @output[0].should == "pelit, 11 days ago:"
      @output[1].should == "F1-kausi alkaa marraskuussa http://bit.ly/1qQwjQ"
      @output[2].should == ""
      @output[58].should == "radar, 15 days ago:"
      @output[59].should == "Four short links: 29 September 2009 http://bit.ly/dYxay"
    end
  end

  Scenario "see home with colorization enabled" do
    When "application is launched with no command" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --colors})
    end

    Then "the latest statuses in the home view are shown" do
      @output[0].should == "\e[32mpelit\e[0m, 11 days ago:"
      @output[1].should == "F1-kausi alkaa marraskuussa \e[36mhttp://bit.ly/1qQwjQ\e[0m"
      @output[2].should == ""
      @output[58].should == "\e[32mradar\e[0m, 15 days ago:"
      @output[59].should == "Four short links: 29 September 2009 \e[36mhttp://bit.ly/dYxay\e[0m"
    end
  end

  Scenario "the command for showing the home view is the default command" do
    When "application is launched with 'home' command" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors home})
    end

    Then "the latest statuses in the home view are shown" do
      @output[0].should == "pelit, 11 days ago:"
      @output[1].should == "F1-kausi alkaa marraskuussa http://bit.ly/1qQwjQ"
      @output[2].should == ""
      @output[58].should == "radar, 15 days ago:"
      @output[59].should == "Four short links: 29 September 2009 http://bit.ly/dYxay"
    end
  end
end
