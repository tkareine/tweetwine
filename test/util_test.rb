require "test_helper"
require "time"

module Tweetwine

class UtilTest < Test::Unit::TestCase
  context "for humanizing time differences" do
    should "use second granularity for time differences smaller than a minute" do
      assert_equal [1,  "sec"], Util.humanize_time_diff(Time.parse("2009-01-01 00:00:59").to_s, Time.parse("2009-01-01 00:01:00"))
      assert_equal [0,  "sec"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:00"))
      assert_equal [1,  "sec"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:01"))
      assert_equal [59, "sec"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:59"))
    end

    should "use minute granularity for time differences greater than a minute but smaller than an hour" do
      assert_equal [59, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 01:59"))
      assert_equal [59, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00:30").to_s, Time.parse("2009-01-01 01:59:00"))
      assert_equal [57, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:00"))
      assert_equal [56, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:01:31").to_s, Time.parse("2009-01-01 01:58:00"))
      assert_equal [57, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:29"))
      assert_equal [58, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:30"))
    end

    should "use hour granularity for time differences greater than an hour but smaller than a day" do
      assert_equal [1,  "hour"],  Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 02:00"))
      assert_equal [1,  "hour"],  Util.humanize_time_diff(Time.parse("2009-01-01 02:00").to_s, Time.parse("2009-01-01 01:00"))
      assert_equal [2,  "hours"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 03:00"))
    end

    should "use day granularity for time differences greater than a day" do
      assert_equal [1,  "day"],  Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-02 03:00"))
      assert_equal [2,  "days"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-03 03:00"))
    end
  end

  context "for recursively symbolizing keys in a hash" do
    should "symbolize hash keys correctly" do
      given = {
        "alpha"   => "A",
        :beta     => "B",
        "charlie" => "C",
        "delta"   => {
          "echelon" => "E",
          "fox"     => "F"
        }
      }
      expected = {
        :alpha    => "A",
        :beta     => "B",
        :charlie  => "C",
        :delta    => {
          :echelon => "E",
          :fox     => "F"
        }
      }
      assert_equal expected, Util.symbolize_hash_keys(given)
    end
  end

  context "for parsing integers from strings, with minimum and default values, and naming parameter" do
    should "return an integer from its string presentation" do
      assert_equal 6, Util.parse_int_gt("6", 8, 4, "ethical working hours per day")
    end

    should "return default value if the string parameter is falsy" do
      assert_equal 8, Util.parse_int_gt(nil, 8, 4, "ethical working hours per day")
      assert_equal 8, Util.parse_int_gt(false, 8, 4, "ethical working hours per day")
    end

    should "raise an error if the parsed value is less than the minimum parameter" do
      assert_raise(ArgumentError) { Util.parse_int_gt(3, 8, 4, "ethical working hours per day") }
      assert_raise(ArgumentError) { Util.parse_int_gt("3", 8, 4, "ethical working hours per day") }
    end
  end

  context "for replacing the contents of a string with a regexp that uses group syntax" do
    should "replace the contents of the string by using a single matching group of the regexp" do
      assert_equal "hEllo", Util.str_gsub_by_group("hello", /.+(e)/) { |s| s.upcase }
      assert_equal "hEllO", Util.str_gsub_by_group("hello", /([aeio])/) { |s| s.upcase }
      assert_equal "hEEllOO", Util.str_gsub_by_group("hello", /([aeio])/) { |s| s.upcase * 2 }
      assert_equal "hll", Util.str_gsub_by_group("hello", /([aeio])/) { |s| "" }
      assert_equal "hell", Util.str_gsub_by_group("hello", /.+([io])/) { |s| "" }
    end

    should "replace the contents of the string by using multiple matching groups of the regexp" do
      assert_equal "hEllO", Util.str_gsub_by_group("hello", /([ae]).+([io])/) { |s| s.upcase }
      assert_equal "hXEXllXOX", Util.str_gsub_by_group("hello", /([ae]).+([io])/) { |s| "X" + s.upcase + "X" }
      assert_equal "hll", Util.str_gsub_by_group("hello", /.+([ae]).+([io])/) { |s| "" }
      assert_equal "hll", Util.str_gsub_by_group("hello", /([ae]).+([io])/) { |s| "" }
      assert_equal "hEllo", Util.str_gsub_by_group("hello", /^(a)|.+(e)/) { |s| s.upcase }
    end

    should "replace the contents of the string by using the whole regexp if there are no groups in the regexp an the regexp matches" do
      assert_equal "", Util.str_gsub_by_group("", /el/) { |s| s.upcase }
      assert_equal "hELlo", Util.str_gsub_by_group("hello", /el/) { |s| s.upcase }
    end

    should "not change the contents of the string if the regexp does not match" do
      assert_equal "", Util.str_gsub_by_group("", /.+([ai])/) { |s| s.upcase }
      assert_equal "hello", Util.str_gsub_by_group("hello", /.+([ai])/) { |s| s.upcase }
      assert_equal "hello", Util.str_gsub_by_group("hello", /he(f)/) { |s| s.upcase }
    end

    should "return a new string as the result, leaving the original string unmodified" do
      org_str = "hello"
      new_str = Util.str_gsub_by_group(org_str, /e/) { |s| s.upcase }
      assert_not_same new_str, org_str
      assert_equal "hello", org_str
      assert_equal "hEllo", new_str
    end
  end
end

end
