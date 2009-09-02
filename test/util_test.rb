require "test_helper"
require "time"

module Tweetwine

class UtilTest < Test::Unit::TestCase
  context "The module" do
    should "humanize time difference" do
      assert_equal [1,  "sec"],   Util.humanize_time_diff(Time.parse("2009-01-01 00:00:59").to_s, Time.parse("2009-01-01 00:01:00"))
      assert_equal [0,  "sec"],   Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:00"))
      assert_equal [1,  "sec"],   Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:01"))
      assert_equal [59, "sec"],   Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:59"))
      assert_equal [59, "min"],   Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 01:59"))
      assert_equal [59, "min"],   Util.humanize_time_diff(Time.parse("2009-01-01 01:00:30").to_s, Time.parse("2009-01-01 01:59:00"))
      assert_equal [57, "min"],   Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:00"))
      assert_equal [56, "min"],   Util.humanize_time_diff(Time.parse("2009-01-01 01:01:31").to_s, Time.parse("2009-01-01 01:58:00"))
      assert_equal [57, "min"],   Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:29"))
      assert_equal [58, "min"],   Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:30"))
      assert_equal [1,  "hour"],  Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 02:00"))
      assert_equal [1,  "hour"],  Util.humanize_time_diff(Time.parse("2009-01-01 02:00").to_s, Time.parse("2009-01-01 01:00"))
      assert_equal [2,  "hours"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 03:00"))
      assert_equal [1,  "day"],   Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-02 03:00"))
      assert_equal [2,  "days"],  Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-03 03:00"))
    end
  end

  should "symbolize hash keys" do
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

  should "parse integers from strings, with minimum and default values, and naming parameter" do
    assert_equal 6, Util.parse_int_gt("6", 8, 4, "ethical working hours per day")
    assert_equal 8, Util.parse_int_gt(nil, 8, 4, "ethical working hours per day")
    assert_equal 8, Util.parse_int_gt(false, 8, 4, "ethical working hours per day")
    assert_raise(ArgumentError) { Util.parse_int_gt(3, 8, 4, "ethical working hours per day") }
  end
end

end
