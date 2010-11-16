# coding: utf-8

require "test_helper"

require "contest"
require "mocha"

Mocha::Configuration.prevent(:stubbing_non_existent_method)

module Tweetwine::Test
  module Assertions
    def assert_contains_exactly(expected, actual, msg = "", &sorter)
      expected = block_given? ? expected.sort(&sorter) : expected.sort
      actual   = block_given? ? actual.sort(&sorter)   : actual.sort
      assert_equal(expected, actual, msg)
    end

    def assert_full_match(regex, str, msg = "")
      match_data = regex.match(str)
      assert(str == match_data.to_s, msg)
    end

    def assert_no_full_match(regex, str, msg = "")
      match_data = regex.match(str)
      assert(str != match_data.to_s, msg)
    end
  end

  module Doubles
    def mock_config
      @config = mock('Config')
      Tweetwine::CLI.stubs(:config).returns(@config)
    end

    def mock_http
      @http = mock('Http')
      Tweetwine::CLI.stubs(:http).returns(@http)
    end

    def mock_oauth
      @oauth = mock('OAuth')
      Tweetwine::CLI.stubs(:oauth).returns(@oauth)
    end

    def mock_ui
      @ui = mock('UI')
      Tweetwine::CLI.stubs(:ui).returns(@ui)
    end

    def mock_url_shortener
      @url_shortener = mock('UrlShortener')
      Tweetwine::CLI.stubs(:url_shortener).returns(@url_shortener)
    end

    def stub_config(options = {})
      @config = options
      Tweetwine::CLI.stubs(:config).returns(@config)
    end
  end

  class UnitTestCase < ::Test::Unit::TestCase
    include WebMock::API
    include Tweetwine
    include Helper
    include Assertions
    include Doubles
  end
end
