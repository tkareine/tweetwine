require "example_helper"

Feature "update my status" do
  in_order_to "tell something about me to the world"
  as_a "user"
  i_want_to "update my status"

  STATUS = "bored. going to sleep."
  INJECTION = 'FakeWeb.register_uri(:post, "https://' + TEST_AUTH + '@twitter.com/statuses/update.json", :body => fixture("update_status.json"))'

  Scenario "update my status from command line with colorization disabled" do
    When "application is launched 'update' command" do
      @status = launch_app("-a #{TEST_AUTH} --no-colors update '#{STATUS}'", INJECTION) do |pid, stdin, stdout|
        stdin.puts "y"
        @output = stdout.readlines
      end
    end

    Then "the status sent is shown" do
      @output[5].should == "#{TEST_USER}, 9 hours ago:\n"
      @output[6].should == "#{STATUS}\n"
      @status.exitstatus.should == 0
    end
  end

  Scenario "update my status from command line with colorization enabled" do
    When "application is launched 'update' command" do
      @status = launch_app("-a #{TEST_AUTH} --colors update '#{STATUS}'", INJECTION) do |pid, stdin, stdout|
        stdin.puts "y"
        @output = stdout.readlines
      end
    end

    Then "the status sent is shown" do
      @output[5].should == "\e[32m#{TEST_USER}\e[0m, 9 hours ago:\n"
      @output[6].should == "#{STATUS}\n"
      @status.exitstatus.should == 0
    end
  end

  Scenario "cancel a status from command line" do
    When "application is launched 'update' command" do
      @status = launch_app("-a #{TEST_AUTH} --colors update '#{STATUS}'", INJECTION) do |pid, stdin, stdout|
        stdin.puts "n"
        @output = stdout.readlines
      end
    end

    Then "a cancellation message is shown" do
      @output[3].should =~ /Cancelled./
      @status.exitstatus.should == 0
    end
  end

  Scenario "update my status from STDIN" do
    When "application is launched 'update' command" do
      @status = launch_app("-a #{TEST_AUTH} --no-colors update", INJECTION) do |pid, stdin, stdout|
        stdin.puts STATUS
        stdin.puts "y"
        @output = stdout.readlines
      end
    end

    Then "the status sent is shown" do
      @output[0].should == "Status update: \n"
      @output[5].should == "#{TEST_USER}, 9 hours ago:\n"
      @output[6].should == "#{STATUS}\n"
      @status.exitstatus.should == 0
    end
  end

  Scenario "cancel a status update from STDIN" do
    When "application is launched 'update' command" do
      @status = launch_app("-a #{TEST_AUTH} --no-colors update", INJECTION) do |pid, stdin, stdout|
        stdin.puts STATUS
        stdin.puts "n"
        @output = stdout.readlines
      end
    end

    Then "a cancellation message is shown" do
      @output[3].should =~ /Cancelled./
      @status.exitstatus.should == 0
    end
  end
end
