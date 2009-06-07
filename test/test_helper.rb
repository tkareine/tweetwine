require "rubygems"
require File.dirname(__FILE__) << "/../lib/tweetwine"
require "test/unit"
require "shoulda"
require "mocha"

Mocha::Configuration.prevent(:stubbing_non_existent_method)

module Test
  module Unit
    class TestCase
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
