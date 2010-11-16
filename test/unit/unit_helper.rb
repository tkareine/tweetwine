# coding: utf-8

require "test_helper"

require "contest"
require "mocha"

Mocha::Configuration.prevent(:stubbing_non_existent_method)

module Tweetwine::Test
  module Helper
    extend self

    def create_test_twitter_status_records_from_rest_api(*internal_records)
      twitter_records = internal_records.map do |internal_record|
        {
          "user"                    => { "screen_name" => internal_record[:from_user] },
          "created_at"              => internal_record[:created_at],
          "text"                    => internal_record[:status],
          "in_reply_to_screen_name" => internal_record[:to_user]
        }
      end
      [twitter_records, internal_records]
    end

    def create_test_twitter_user_records_from_rest_api(*internal_records)
      twitter_records = internal_records.map do |internal_record|
        twitter_record = { "screen_name" => internal_record[:from_user] }
        if internal_record[:status]
          twitter_record.merge!({
            "status" => {
              "created_at"              => internal_record[:created_at],
              "text"                    => internal_record[:status],
              "in_reply_to_screen_name" => internal_record[:to_user],
            }
          })
        end
        twitter_record
      end
      [twitter_records, internal_records]
    end

    def create_test_twitter_records_from_search_api(*internal_records)
      twitter_search_records = internal_records.map do |internal_record|
        {
          "from_user"   => internal_record[:from_user],
          "created_at"  => internal_record[:created_at],
          "text"        => internal_record[:status],
          "to_user"     => internal_record[:to_user]
        }
      end
      twitter_records = {
        "results" => twitter_search_records
      }
      [twitter_records, internal_records]
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

  class UnitTestCase < ::Test::Unit::TestCase
    include WebMock::API
    include Tweetwine
    include Helper
    include Doubles
    include Assertions
  end
end
