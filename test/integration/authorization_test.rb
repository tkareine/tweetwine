# coding: utf-8

require 'integration/helper'
require 'fixture/oauth'

module Tweetwine::Test::Integration

class AuthorizationTest < TestCase
  include Test::Fixture::OAuth

  describe "authorize user with OAuth and save access token" do
    before do
      @command_url = "https://api.twitter.com/1/statuses/home_timeline.json?count=20&page=1"
      stub_http_request(METHOD, REQUEST_TOKEN_URL).to_return(:body => REQUEST_TOKEN_RESPONSE)
      stub_http_request(METHOD, ACCESS_TOKEN_URL).to_return(:body => ACCESS_TOKEN_RESPONSE)
      stub_http_request(:get, @command_url).
        to_return(:status => [401, 'Unauthorized']).then.
        to_return(:body => fixture_file('home.json'))
      in_tmp_dir do
        config_file = 'tweetwine.tmp'
        @output = start_cli %W{--no-colors -f #{config_file} home}, [PIN], {}
        @config_contents = YAML.load_file(config_file)
        @config_mode = file_mode(config_file)
      end
    end

    it "authorizes me, saves access token to config file, and tries the command again" do
      assert_requested(METHOD, REQUEST_TOKEN_URL)
      assert_requested(METHOD, ACCESS_TOKEN_URL)
      assert_requested(:get, @command_url, :headers => {'Authorization' => /^OAuth /}, :times => 2)
      @output[0].must_equal "Please authorize: #{AUTHORIZE_URL}"
      @output[1].must_match(/^Enter PIN:/)
      @output[2].must_equal "F1-kausi alkaa marraskuussa http://bit.ly/1qQwjQ"
      @config_contents['oauth_access'].empty?.must_equal false
      @config_mode.must_equal 0600
    end
  end
end

end
