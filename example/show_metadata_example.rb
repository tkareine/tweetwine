require "example_helper"

Feature "show metadata" do
  in_order_to "know about the application"
  as_a "user"
  i_want_to "see application metadata"

  Scenario "see version with designated exit status" do
    When "application is launched with -v" do
      @status = launch_app("-v") do |pid, stdin, stdout|
        @output = stdout.gets
      end
    end

    Then "version is shown" do
      @output.should =~ /\d\.\d\.\d$/
      @status.exitstatus.should == CLI::EXIT_VERSION
    end
  end

  Scenario "see help with designated exit status" do
    When "application is launched with -h" do
      @status = launch_app("-h") do |pid, stdin, stdout|
        @output = stdout.readlines
      end
    end

    Then "help is shown" do
      @output[2].should =~ /^Usage:.* \[global_options\.\.\.\] \[command\] \[command_options\.\.\.\]/
      @output[4].should =~ /\[command\] is one of \{#{Client::COMMANDS.join(", ")}\},/
      @output[5].should =~ /defaulting to #{Client::DEFAULT_COMMAND}/
      @output[7].should =~ /\[global_options\]:$/
      @status.exitstatus.should == CLI::EXIT_HELP
    end
  end

  Scenario "upon invalid option, use designated exit status" do
    When "application is launched with -X" do
      @status = launch_app("-X") do |pid, stdin, stdout|
        @output = stdout.readlines
      end
    end

    Then "designated exit status is returned" do
      @status.exitstatus.should == CLI::EXIT_ERROR
    end
  end

  Scenario "upon invalid command, use designated exit status" do
    When "application is launched with 'unknown'" do
      @status = launch_app("unknown") do |pid, stdin, stdout|
        @output = stdout.readlines
      end
    end

    Then "designated exit status is returned" do
      @status.exitstatus.should == CLI::EXIT_ERROR
    end
  end
end
