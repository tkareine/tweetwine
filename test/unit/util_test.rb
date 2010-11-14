# coding: utf-8

require "unit_helper"

require "time"

module Tweetwine::Test

class UtilTest < UnitTestCase
  include Util

  context "for checking whether a string is blank" do
    should("return true for nil")               { assert blank?(nil)  }
    should("return true for empty string")      { assert blank?('')   }
    should("return false for nonempty string")  { assert !blank?('a') }
  end

  context "for humanizing time differences" do
    should "use second granularity for time differences smaller than a minute" do
      assert_equal [1,  "sec"], humanize_time_diff(Time.parse("2009-01-01 00:00:59").to_s, Time.parse("2009-01-01 00:01:00"))
      assert_equal [0,  "sec"], humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:00"))
      assert_equal [1,  "sec"], humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:01"))
      assert_equal [59, "sec"], humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:59"))
    end

    should "use minute granularity for time differences greater than a minute but smaller than an hour" do
      assert_equal [59, "min"], humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 01:59"))
      assert_equal [59, "min"], humanize_time_diff(Time.parse("2009-01-01 01:00:30").to_s, Time.parse("2009-01-01 01:59:00"))
      assert_equal [57, "min"], humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:00"))
      assert_equal [56, "min"], humanize_time_diff(Time.parse("2009-01-01 01:01:31").to_s, Time.parse("2009-01-01 01:58:00"))
      assert_equal [57, "min"], humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:29"))
      assert_equal [58, "min"], humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:30"))
    end

    should "use hour granularity for time differences greater than an hour but smaller than a day" do
      assert_equal [1,  "hour"],  humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 02:00"))
      assert_equal [1,  "hour"],  humanize_time_diff(Time.parse("2009-01-01 02:00").to_s, Time.parse("2009-01-01 01:00"))
      assert_equal [2,  "hours"], humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 03:00"))
    end

    should "use day granularity for time differences greater than a day" do
      assert_equal [1,  "day"],  humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-02 03:00"))
      assert_equal [2,  "days"], humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-03 03:00"))
    end
  end

  context "for recursively copying a hash" do
    ALL_KEYS_STRINGS = {
      'alpha'   => 'A',
      'beta'    => 'B',
      'charlie' => 'C',
      'delta'   => {
        'echelon' => 'E',
        'fox'     => 'F'
      }
    }
    ALL_KEYS_SYMBOLS = {
      :alpha    => 'A',
      :beta     => 'B',
      :charlie  => 'C',
      :delta    => {
        :echelon => 'E',
        :fox     => 'F'
      }
    }

    should "stringify hash keys" do
      given = {
        :alpha    => 'A',
        'beta'    => 'B',
        :charlie  => 'C',
        :delta    => {
          :echelon  => 'E',
          'fox'     => 'F'
        }
      }
      assert_equal ALL_KEYS_STRINGS, stringify_hash_keys(given)
    end

    should "symbolize hash keys" do
      given = {
        'alpha'   => 'A',
        :beta     => 'B',
        'charlie' => 'C',
        'delta'   => {
          'echelon' => 'E',
          :fox      => 'F'
        }
      }
      assert_equal ALL_KEYS_SYMBOLS, symbolize_hash_keys(given)
    end

    should "have symmetric property for stringify and symbolize" do
      assert_equal ALL_KEYS_STRINGS, stringify_hash_keys(symbolize_hash_keys(ALL_KEYS_STRINGS))
      assert_equal ALL_KEYS_SYMBOLS, symbolize_hash_keys(stringify_hash_keys(ALL_KEYS_SYMBOLS))
    end
  end

  context "for parsing integers from strings, with minimum and default values, and naming parameter" do
    should "return an integer from its string presentation" do
      assert_equal 6, parse_int_gt("6", 8, 4, "ethical working hours per day")
    end

    should "return default value if the string parameter is falsy" do
      assert_equal 8, parse_int_gt(nil, 8, 4, "ethical working hours per day")
      assert_equal 8, parse_int_gt(false, 8, 4, "ethical working hours per day")
    end

    should "raise an error if the parsed value is less than the minimum parameter" do
      assert_raise(ArgumentError) { parse_int_gt(3, 8, 4, "ethical working hours per day") }
      assert_raise(ArgumentError) { parse_int_gt("3", 8, 4, "ethical working hours per day") }
    end
  end

  context "for replacing the contents of a string with a regexp that uses group syntax" do
    should "replace the contents of the string by using a single matching group of the regexp" do
      assert_equal "hEllo", str_gsub_by_group("hello", /.+(e)/) { |s| s.upcase }
      assert_equal "hEllO", str_gsub_by_group("hello", /([aeio])/) { |s| s.upcase }
      assert_equal "h<b>e</b>ll<b>o</b>", str_gsub_by_group("hello", /([aeio])/) { |s| "<b>#{s}</b>" }
      assert_equal "hll", str_gsub_by_group("hello", /([aeio])/) { |s| "" }
      assert_equal "hell", str_gsub_by_group("hello", /.+([io])/) { |s| "" }
    end

    should "replace the contents of the string by using multiple matching groups of the regexp" do
      assert_equal "hEllO", str_gsub_by_group("hello", /([ae]).+([io])/) { |s| s.upcase }
      assert_equal "h<b>e</b>ll<b>o</b>", str_gsub_by_group("hello", /([ae]).+([io])/) { |s| "<b>#{s}</b>" }
      assert_equal "hll", str_gsub_by_group("hello", /.+([ae]).+([io])/) { |s| "" }
      assert_equal "hll", str_gsub_by_group("hello", /([ae]).+([io])/) { |s| "" }
      assert_equal "hEllo", str_gsub_by_group("hello", /^(a)|.+(e)/) { |s| s.upcase }
    end

    should "replace the contents of the string by using the whole regexp if there are no groups in the regexp an the regexp matches" do
      assert_equal "", str_gsub_by_group("", /el/) { |s| s.upcase }
      assert_equal "hELlo", str_gsub_by_group("hello", /el/) { |s| s.upcase }
      assert_equal "h<b>e</b>ll<b>o</b>", str_gsub_by_group("hello", /e|o/) { |s| "<b>#{s}</b>" }
    end

    should "not change the contents of the string if the regexp does not match" do
      assert_equal "", str_gsub_by_group("", /.+([ai])/) { |s| s.upcase }
      assert_equal "hello", str_gsub_by_group("hello", /.+([ai])/) { |s| s.upcase }
      assert_equal "hello", str_gsub_by_group("hello", /he(f)/) { |s| s.upcase }
    end

    should "return a new string as the result, leaving the original string unmodified" do
      org_str = "hello"
      new_str = str_gsub_by_group(org_str, /e/) { |s| s.upcase }
      assert_not_same new_str, org_str
      assert_equal "hello", org_str
      assert_equal "hEllo", new_str
    end

    should "work with UTF-8 input" do
      assert_equal "Ali<b>en</b>³,<b>Pre</b>dator", str_gsub_by_group("Alien³,Predator", /(en).+(Pre)/) { |s| "<b>#{s}</b>" }
    end
  end

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
        assert_equal char, percent_encode(char)
      end
    end

    should "encode space character with percent-encoding, not with '+' character" do
      assert_equal "%20", percent_encode(" ")
    end

    [
      %w{& %26 ampersand},
      %w{? %3F question mark},
      %w{/ %2F slash},
      %w{: %3A colon},
      %w{, %2C comma}
    ].each do |char, expected, desc|
      should "encode unsafe characters that URI.encode leaves by default unencoded, case #{desc}" do
        assert_equal char, URI.encode(char)
        assert_equal expected, percent_encode(char)
      end
    end
  end

  context "for unescaping HTML" do
    [
      %w{a a},
      %w{B B},
      %w{3 3},
      %w{. period},
      %w{- dash},
      %w{_ underscore},
      %w{+ plus}
    ].each do |char, desc|
      should "not affect already unescaped characters, case #{desc}" do
        assert_equal char, unescape_html(char)
      end
    end

    [
      %w{&lt;   <},
      %w{&gt;   >},
      %w{&amp;  &},
      %w{&quot; "},
      %W{&nbsp; \ }
    ].each do |input, expected|
      should "unescape HTML-escaped characters, case '#{input}'" do
        assert_equal expected, unescape_html(input)
      end
    end
  end

  context "for traversing a hash with a path expression for finding a value" do
    setup do
      @inner_hash = {
        :salmon => "slick"
      }
      @inner_hash.default = "no such element in inner hash"
      @outer_hash = {
        :simple => "beautiful",
        :inner  => @inner_hash,
        :fishy  => nil
      }
      @outer_hash.default = "no such element in outer hash"
    end

    should "support both a non-array and a single element array path for finding the value" do
      assert_equal "beautiful", find_hash_path(@outer_hash, :simple)
      assert_equal "beautiful", find_hash_path(@outer_hash, [:simple])
    end

    should "find a nested value with an array path" do
      assert_equal "slick", find_hash_path(@outer_hash, [:inner, :salmon])
    end

    should "return the default value of the hash if the value cannot be found" do
      assert_equal @outer_hash.default, find_hash_path(@outer_hash, :difficult)
      assert_equal @inner_hash.default, find_hash_path(@outer_hash, [:inner, :cucumber])
      assert_equal @outer_hash.default, find_hash_path(@outer_hash, [:fishy, :no_such])
    end

    should "return the default value of the hash if invalid path value" do
      assert_equal @outer_hash.default, find_hash_path(@outer_hash, nil)
      assert_equal @outer_hash.default, find_hash_path(@outer_hash, [:no_such, nil])
      assert_equal @outer_hash.default, find_hash_path(@outer_hash, [:simple, nil])
      assert_equal @outer_hash.default, find_hash_path(@outer_hash, [:inner, nil])
      assert_equal @outer_hash.default, find_hash_path(@outer_hash, [:inner, :salmon, nil])
    end

    should "return nil if nil hash value" do
      assert_equal nil, find_hash_path(nil, nil)
    end
  end
end

end
