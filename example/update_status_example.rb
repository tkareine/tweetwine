# coding: utf-8

require "example_helper"

FakeWeb.register_uri(:post, "https://#{TEST_AUTH}@twitter.com/statuses/update.json", :body => fixture("update.json"))

Feature "update my status" do
  in_order_to "tell something about me to the world"
  as_a "authenticated user"
  i_want_to "update my status"

  STATUS = "bored. going to sleep."

  Scenario "update my status from command line with colorization disabled" do
    When "application is launched 'update' command" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors update '#{STATUS}'}, "y")
    end

    Then "the status sent is shown" do
      @output[5].should == "#{TEST_USER}, 9 hours ago:"
      @output[6].should == "#{STATUS}"
    end
  end

  Scenario "update my status from command line with colorization enabled" do
    When "application is launched 'update' command" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --colors update '#{STATUS}'}, "y")
    end

    Then "the status sent is shown" do
      @output[5].should == "\e[32m#{TEST_USER}\e[0m, 9 hours ago:"
      @output[6].should == "#{STATUS}"
    end
  end

  Scenario "cancel a status from command line" do
    When "application is launched 'update' command" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --colors update '#{STATUS}'}, "n")
    end

    Then "a cancellation message is shown" do
      @output[3].should =~ /Cancelled./
    end
  end

  Scenario "update my status from STDIN" do
    When "application is launched 'update' command" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors update}, STATUS, "y")
    end

    Then "the status sent is shown" do
      @output[0].should == "Status update: "
      @output[5].should == "#{TEST_USER}, 9 hours ago:"
      @output[6].should == "#{STATUS}"
    end
  end

  Scenario "cancel a status update from STDIN" do
    When "application is launched 'update' command" do
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors update}, STATUS, "n")
    end

    Then "a cancellation message is shown" do
      @output[3].should =~ /Cancelled./
    end
  end
end
