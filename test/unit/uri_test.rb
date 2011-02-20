# coding: utf-8

require "unit_helper"

module Tweetwine::Test

class UriTest < UnitTestCase
  context "for percent-encoding strings" do
    [
      %w{a a},
      %w{B B},
      %w{3 3},
      %w{. period},
      %w{- dash},
      %w{_ underscore},
    ].each do |char, desc|
      should "not encode safe characters, case #{desc}" do
        assert_equal char, Uri.percent_encode(char)
      end
    end

    should "encode space character with percent-encoding, not with '+' character" do
      assert_equal "%20", Uri.percent_encode(" ")
    end

    [
      %w{& %26 ampersand},
      %w{? %3F question mark},
      %w{/ %2F slash},
      %w{: %3A colon},
      %w{, %2C comma}
    ].each do |char, expected, desc|
      should "encode unsafe characters that URI.encode leaves by default unencoded, case #{desc}" do
        assert_equal char, Uri.parser.escape(char)
        assert_equal expected, Uri.percent_encode(char)
      end
    end
  end
end

end
