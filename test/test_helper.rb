require "rubygems"
require File.dirname(__FILE__) << "/../lib/tweetwine"
require "test/unit"
require "shoulda"
require "mocha"

module Tweetwine
  module TestHelpers
    def create_test_statuses(*records)
      statuses = records.map do |record|
        {
          "created_at"              => record[:status][:created_at],
          "text"                    => record[:status][:text],
          "in_reply_to_screen_name" => record[:status][:in_reply_to],
          "user"                    => { "screen_name" => record[:user] }
        }
      end
      [statuses, records]
    end

    def create_test_users(*records)
      statuses = records.map do |record|
        {
          "screen_name" => record[:user],
          "status"      => {
            "created_at"              => record[:status][:created_at],
            "text"                    => record[:status][:text],
            "in_reply_to_screen_name" => record[:status][:in_reply_to],
          }
        }
      end
      [statuses, records]
    end
  end
end

Mocha::Configuration.prevent(:stubbing_non_existent_method)

module Test
  module Unit
    class TestCase
      include Tweetwine::TestHelpers

      def assert_full_match(regex, str, msg = "")
        match_data = regex.match(str)
        assert(str == match_data.to_s, msg)
      end

      def assert_no_full_match(regex, str, msg = "")
        match_data = regex.match(str)
        assert(str != match_data.to_s, msg)
      end
    end
  end
end
