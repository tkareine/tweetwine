# coding: utf-8

require "tweetwine"
require "contest"
require "json"              # for webmock
require "mocha"
require "webmock/test_unit"

Mocha::Configuration.prevent(:stubbing_non_existent_method)
WebMock.disable_net_connect!

module Tweetwine
  module Test
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

      def file_mode(file)
        File.stat(file).mode & 0777
      end

      def fixture_file(filename)
        File.dirname(__FILE__) << "/fixture/" << filename
      end

      def mock_http
        @http = mock
        CLI.stubs(:http).returns(@http)
      end

      def mock_ui
        @ui = mock
        CLI.stubs(:ui).returns(@ui)
      end

      def mock_url_shortener
        @url_shortener = mock
        CLI.stubs(:url_shortener).returns(@url_shortener)
      end

      def stub_config(options = {})
        @config = options
        CLI.stubs(:config).returns(@config)
      end

      def tmp_env(vars = {})
        originals = {}
        vars.each_pair do |key, value|
          key = key.to_s
          originals[key] = ENV[key]
          ENV[key] = value
        end
        yield
      ensure
        originals.each_pair do |key, value|
          ENV[key] = value
        end
      end

      def tmp_kcode(val)
        original = $KCODE
        $KCODE = val
        yield
      ensure
        $KCODE = original
      end
    end

    module Assertions
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
      include Assertions
    end
  end
end
