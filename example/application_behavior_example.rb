# coding: utf-8

require "example_helper"

Feature "application behavior" do
  in_order_to "know about the application"
  as_a "user"
  i_want_to "see helpful messages"

  [%w{-v}, %w{version}, %w{ver}, %w{v}].each do |args|
    args_desc = "'#{args.join(' ')}'"

    Scenario "show version with arguments #{args_desc}" do
      When "I start the application with #{args_desc}" do
        @status = start_app args do |_, _, stdout|
          @output = stdout.gets
        end
      end

      Then "the application shows version and exists with success status" do
        @output.should =~ /\d+\.\d+\.\d+$/
        @status.exitstatus.should == 0
      end
    end
  end

  [%w{-h}, %w{help}].each do |args|
    args_desc = "'#{args.join(' ')}'"

    Scenario "show help with arguments #{args_desc}" do
      When "I start the application with #{args_desc}" do
        @status = start_app args do |_, _, stdout|
          @output = stdout.readlines
        end
      end

      Then "the application shows help and exists with success status" do
        @output.join.should == <<-END
A simple but tasty Twitter agent for command line use, made for fun.

Usage: tweetwine [global_options...] [<command>] [command_options...]

  Global options:

    -c, --colors                     Enable ANSI colors for output.
    -h, --help                       Show this help and exit.
        --http-proxy <url>           Enable HTTP(S) proxy.
        --no-colors                  Disable ANSI colors for output.
        --no-http-proxy              Disable HTTP(S) proxy.
        --no-url-shorten             Disable URL shortening.
    -n, --num <n>                    Number of statuses per page (default 20).
    -p, --page <p>                   Page number for statuses (default 1).
    -u, --username <user>            User to authenticate (default '#{USER}').
    -v, --version                    Show version and exit.

  Commands:

    followers     Show authenticated user's followers and their latest tweets.
    friends       Show authenticated user's friends and their latest tweets.
    help          Show help and exit. Try it with <command> argument.
    home          Show authenticated user's home timeline (the default command).
    mentions      Show latest tweets that mention or are replies to the authenticated user.
    search        Search latest public tweets.
    update        Send new tweet.
    user          Show user's timeline.
    version       Show program version and exit.
        END
        @status.exitstatus.should == 0
      end
    end
  end

  Scenario "upon invalid option, exit with failure status" do
    When "I start the application with invalid option" do
      @status = start_app %w{-X} do |_, _, stdout|
        @output = stdout.readlines
      end
    end

    Then "the application exists with failure status" do
      @status.exitstatus.should == CommandLineError.status_code
    end
  end

  Scenario "upon invalid command, exit with failure status" do
    When "I start the application with invalid command" do
      @status = start_app %w{invalid} do |_, _, stdout|
        @output = stdout.readlines
      end
    end

    Then "the application exists with failure status" do
      @status.exitstatus.should == UnknownCommandError.status_code
    end
  end
end
