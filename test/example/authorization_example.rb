# coding: utf-8

require 'example/helper'
require 'fixture/oauth'

include Tweetwine::Test::Fixture::OAuth

Feature "authorization" do
  as_a "user"
  i_want_to "see authorize myself"
  in_order_to "use the service"

  Scenario "authorize user with OAuth and save access token" do
    When "I start the application with 'home' command and the command fails due to me being unauthorized" do
      @command_url = "https://api.twitter.com/1/statuses/home_timeline.json?count=20&page=1"
      stub_http_request(METHOD, REQUEST_TOKEN_URL).to_return(:body => REQUEST_TOKEN_RESPONSE)
      stub_http_request(METHOD, ACCESS_TOKEN_URL).to_return(:body => ACCESS_TOKEN_RESPONSE)
      stub_http_request(:get, @command_url).
        to_return(:status => [401, 'Unauthorized']).then.
        to_return(:body => fixture_file('home.json'))
      in_temp_dir do
        config_file = 'tweetwine.tmp'
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