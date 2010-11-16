# coding: utf-8

require "example_helper"
require "fixture/oauth"

include Tweetwine::Test::Fixture::OAuth

Feature "application behavior" do
  in_order_to "know about the application"
  as_a "user"
  i_want_to "see helpful messages"

  %w{-v version ver v}.each do |arg|
    Scenario "show version with '#{arg}'" do
      When "I start the application with '#{arg}'" do
        @status = start_app [arg] do |_, _, stdout|
          @output = stdout.readlines.join
        end
      end

      Then "the application shows version and exists with success status" do
        @output.should =~ /\d+\.\d+\.\d+$/
        @status.exitstatus.should == 0
      end
    end
  end

  %w{-h help}.each do |arg|
    Scenario "show general help with '#{arg}'" do
      When "I start the application with '#{arg}'" do
        @status = start_app [arg] do |_, _, stdout|
          @output = stdout.readlines.join
        end
      end

      Then "the application shows help and exists with success status" do
        @output.should == <<-END
A simple but tasty Twitter agent for command line use, made for fun.

Usage: #{CLI::EXEC_NAME} [global_options...] [<command>] [command_options...]

  Global options:

    -c, --colors                     Enable ANSI colors for output.
    -f, --config <file>              Configuration file (default #{CLI::DEFAULT_CONFIG[:config_file]}).
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

    %w{followers friends help home mentions search update user version}.each do |command|
      Scenario "show command specific help with '#{arg} #{command}'" do
        When "I start the application with '#{arg} #{command}'" do
          @status = start_app [arg, command] do |_, _, stdout|
            @output = stdout.readlines.join
          end
        end

        Then "the application shows help about the command and exits with success status" do
          cmd_class = Tweetwine::CLI.const_get("#{command.capitalize}Command")
          expected_about = cmd_class.about
          expected_usage = "Usage: tweetwine #{command} #{cmd_class.usage}".strip
          @output.should == <<-END
#{expected_about}

#{expected_usage}
          END
          @status.exitstatus.should == 0
        end
      end
    end

    Scenario "show help command's help with '#{arg} <invalid_command>'" do
      When "I start the application with '#{arg} invalid'" do
        @status = start_app [arg, 'invalid'] do |_, _, stdout, stderr|
          @stdout = stdout.readlines.join
          @stderr = stderr.readlines.join
        end
      end

      Then "the application shows help about help command and exits with failure status" do
        @stderr.should == "ERROR: unknown command: invalid\n\n"
        @stdout.should == <<-END
Show help and exit. Try it with <command> argument.

Usage: tweetwine help [<command>]

  If <command> is given, show specific help about that command. If no
  <command> is given, show general help.
        END
        @status.exitstatus.should == CommandLineError.status_code
      end
    end
  end

  Scenario "show error and exit with failure status when invalid option" do
    When "I start the application with invalid option" do
      @status = start_app %w{-X} do |_, _, _, stderr|
        @output = stderr.readlines.join.chomp
      end
    end

    Then "the application exists with failure status" do
      @output.should == 'ERROR: invalid option: -X'
      @status.exitstatus.should == CommandLineError.status_code
    end
  end

  Scenario "show error and exit with failure status when invalid command" do
    When "I start the application with invalid command" do
      @status = start_app %w{invalid} do |_, _, _, stderr|
        @output = stderr.readlines.join.chomp
      end
    end

    Then "the application exists with failure status" do
      @output.should == 'ERROR: unknown command: invalid'
      @status.exitstatus.should == UnknownCommandError.status_code
    end
  end

  Scenario "authorize user with OAuth and save access token" do
    When "I start the application with 'home' command and the command fails due to me being unauthorized" do
      @command_url = "https://api.twitter.com/1/statuses/home_timeline.json?count=20&page=1"
      stub_http_request(METHOD, REQUEST_TOKEN_URL).to_return(:body => REQUEST_TOKEN_RESPONSE)
      stub_http_request(METHOD, ACCESS_TOKEN_URL).to_return(:body => ACCESS_TOKEN_RESPONSE)
      stub_http_request(:get, @command_url).
          to_return(:status => [401, 'Unauthorized']).then.
          to_return(:body => fixture_file('home.json'))
      @output = nil
      @config_contents = nil
      @config_mode = nil
      config_file = 'tweetwine.tmp'
      in_temp_dir do
        @output = start_cli %W{--no-colors -f #{config_file} home}, [PIN], {}
        @config_contents = YAML.load_file(config_file)
        @config_mode = file_mode(config_file)
      end
    end

    Then "the application authorizes me, saves access token to config file, and tries the command again" do
      assert_requested(METHOD, REQUEST_TOKEN_URL)
      assert_requested(METHOD, ACCESS_TOKEN_URL)
      assert_requested(:get, @command_url, :headers => {'Authorization' => /^OAuth /}, :times => 2)
      @output[0].should == "Please authorize: #{AUTHORIZE_URL}"
      @output[1].should =~ /^Enter PIN:/
      @output[2].should == "F1-kausi alkaa marraskuussa http://bit.ly/1qQwjQ"
      @config_contents['oauth_access'].empty?.should == false
      @config_mode.should == 0600
    end
  end
end
