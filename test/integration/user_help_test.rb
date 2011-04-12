# coding: utf-8

require 'integration/helper'

module Tweetwine::Test

class UserHelpTest < IntegrationTest
  %w{-v version ver v}.each do |arg|
    describe "show version with '#{arg}'" do
      before do
        @status = start_app [arg] do |_, _, stdout|
          @output = stdout.readlines.join
        end
      end

      it "shows version and exists with success status" do
        @output.must_match(/\d+\.\d+\.\d+$/)
        @status.exitstatus.must_equal 0
      end
    end
  end

  %w{-h help}.each do |arg|
    describe "show general help with '#{arg}'" do
      before do
        @status = start_app [arg] do |_, _, stdout|
          @output = stdout.readlines.join
        end
      end

      it "shows help and exists with success status" do
        @output.must_equal <<-END
#{Tweetwine.summary}

Usage: #{CLI::EXEC_NAME} [global_options...] [<command>] [command_options...]

  Global options:

    -c, --colors                     Enable ANSI colors for output.
    -f, --config <file>              Configuration file (default #{CLI::DEFAULT_CONFIG[:config_file]}).
    -h, --help                       Show this help and exit.
        --http-proxy <url>           Enable HTTP(S) proxy.
        --no-colors                  Disable ANSI colors for output.
        --no-http-proxy              Disable HTTP(S) proxy.
        --no-url-shorten             Disable URL shortening.
    -n, --num <n>                    Number of tweets per page (default 20).
    -p, --page <p>                   Page number for tweets (default 1).
    -r, --reverse                    Show tweets in reverse order (default false).
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
        @status.exitstatus.must_equal 0
      end
    end

    %w{followers friends help home mentions search update user version}.each do |command|
      describe "show command specific help with '#{arg} #{command}'" do
        before do
          @status = start_app [arg, command] do |_, _, stdout|
            @output = stdout.readlines.join
          end
        end

        it "shows help about the command and exits with success status" do
          cmd_class = Tweetwine::CLI.const_get("#{command.capitalize}Command")
          expected_about = cmd_class.about
          expected_usage = "Usage: tweetwine #{command} #{cmd_class.usage}".strip
          @output.must_equal <<-END
#{expected_about}

#{expected_usage}
          END
          @status.exitstatus.must_equal 0
        end
      end
    end

    describe "show help command's help with '#{arg} <invalid_command>'" do
      before do
        @status = start_app [arg, 'invalid'] do |_, _, stdout, stderr|
          @stdout = stdout.readlines.join
          @stderr = stderr.readlines.join
        end
      end

      it "shows help about help command and exits with failure status" do
        @stderr.must_equal "ERROR: unknown command: invalid\n\n"
        @stdout.must_equal <<-END
Show help and exit. Try it with <command> argument.

Usage: tweetwine help [<command>]

  If <command> is given, show specific help about that command. If no
  <command> is given, show general help.
        END
        @status.exitstatus.must_equal CommandLineError.status_code
      end
    end
  end

  describe "show error and exit with failure status when invalid option" do
    before do
      @status = start_app %w{-X} do |_, _, _, stderr|
        @output = stderr.readlines.join.chomp
      end
    end

    it "exists with failure status" do
      @output.must_equal 'ERROR: invalid option: -X'
      @status.exitstatus.must_equal CommandLineError.status_code
    end
  end

  describe "show error and exit with failure status when invalid command" do
    before do
      @status = start_app %w{invalid} do |_, _, _, stderr|
        @output = stderr.readlines.join.chomp
      end
    end

    it "exists with failure status" do
      @output.must_equal 'ERROR: unknown command: invalid'
      @status.exitstatus.must_equal UnknownCommandError.status_code
    end
  end
end

end
