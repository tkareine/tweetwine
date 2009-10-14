require "example_helper"

Feature "show metadata" do
  in_order_to "know about the application"
  as_a "user"
  i_want_to "see application metadata"

  Scenario "see version" do
    When "application is launched with -v" do
      @status = launch_app("-v") do |pid, stdin, stdout|
        @output = stdout.gets
      end
    end

    Then "version is shown" do
      @output.should =~ /\d\.\d\.\d$/
      @status.exitstatus.should == 2
    end
  end

  Scenario "see help" do
    When "application is launched with -h" do
      @status = launch_app("-h") do |pid, stdin, stdout|
        @output = stdout.readlines
      end
    end

    Then "help is shown" do
      @output[0].should =~ /^Usage:.* \[options\.\.\.\] \[command\]/
      @output[2].should =~ /Commands: #{Client::COMMANDS.join(", ")}/
      @output[4].should =~ /Options:$/
      @status.exitstatus.should == 1
    end
  end
end
