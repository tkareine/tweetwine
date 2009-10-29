require "example_helper"

Feature "show the latest statuses" do
  in_order_to "stay up-to-date"
  as_a "user"
  i_want_to "see the latest statuses"

  INJECTION = 'FakeWeb.register_uri(:get, "https://foouser:barpwd@twitter.com/statuses/friends_timeline.json?count=20&page=1", :body => fixture("statuses.json"))'

  Scenario "see the latest statuses with colorization disabled" do
    When "application is launched with command 'home'" do
      @status = launch_app("-a foouser:barpwd --no-colors", INJECTION) do |pid, stdin, stdout|
        @output = stdout.readlines
      end
    end

    Then "the latest statuses are shown" do
      @output[0].should == "pelit, 11 days ago:\n"
      @output[1].should == "F1-kausi alkaa marraskuussa http://bit.ly/1qQwjQ\n"
      @output[2].should == "\n"
      @output[58].should == "radar, 15 days ago:\n"
      @output[59].should == "Four short links: 29 September 2009 http://bit.ly/dYxay\n"
      @output[60].should == "\n"
      @status.exitstatus.should == 0
    end
  end

  Scenario "see the latest statuses with colorization enabled" do
    When "application is launched with command 'home'" do
      @status = launch_app("-a foouser:barpwd --colors", INJECTION) do |pid, stdin, stdout|
        @output = stdout.readlines
      end
    end

    Then "the latest statuses are shown" do
      @output[0].should == "\e[32mpelit\e[0m, 11 days ago:\n"
      @output[1].should == "F1-kausi alkaa marraskuussa \e[36mhttp://bit.ly/1qQwjQ\e[0m\n"
      @output[2].should == "\n"
      @output[58].should == "\e[32mradar\e[0m, 15 days ago:\n"
      @output[59].should == "Four short links: 29 September 2009 \e[36mhttp://bit.ly/dYxay\e[0m\n"
      @output[60].should == "\n"
      @status.exitstatus.should == 0
    end
  end
end
