require "tweetwine"
require "test/unit"
require "shoulda"
require "mocha"

module Tweetwine
  module TestHelpers
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
