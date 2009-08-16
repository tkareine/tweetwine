require "rubygems"
require File.dirname(__FILE__) << "/../lib/tweetwine"
require "test/unit"
require "shoulda"
require "mocha"

module Tweetwine
  module TestHelpers
    def create_test_statuses(*gen_records)
      status_records = gen_records.map do |gen_record|
        {
          "user"                    => { "screen_name" => gen_record[:user] },
          "created_at"              => gen_record[:status][:created_at],
          "text"                    => gen_record[:status][:text],
          "in_reply_to_screen_name" => gen_record[:status][:in_reply_to]
        }
      end
      [status_records, gen_records]
    end

    def create_test_users(*gen_records)
      user_records = gen_records.map do |gen_record|
        user_record = { "screen_name" => gen_record[:user] }
        if gen_record[:status]
          user_record.merge!({
            "status" => {
              "created_at"              => gen_record[:status][:created_at],
              "text"                    => gen_record[:status][:text],
              "in_reply_to_screen_name" => gen_record[:status][:in_reply_to],
            }
          })
        end
        user_record
      end
      [user_records, gen_records]
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
