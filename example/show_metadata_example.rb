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
      @output.join.should == <<-END
A simple but tasty Twitter agent for command line use, made for fun.

Usage: tweetwine [global_options...] [command] [command_options...]

  [command] is one of
    * followers,
    * friends,
    * home,
    * mentions,
    * search,
    * update, or
    * user.

  The default command is home.

  [global_options]:
    -a, --auth USERNAME:PASSWORD     Authentication
    -c, --colors                     Colorize output with ANSI escape codes
    -n, --num N                      The number of statuses in page, default 20
        --no-colors                  Do not use ANSI colors
        --no-http-proxy              Do not use proxy for HTTP and HTTPS
        --no-url-shorten             Do not shorten URLs for status update
    -p, --page N                     The page number for statuses, default 1
        --http-proxy URL             Use proxy for HTTP and HTTPS
    -v, --version                    Show version information and exit
    -h, --help                       Show this help message and exit
      END
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
