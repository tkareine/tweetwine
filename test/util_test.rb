require File.dirname(__FILE__) << "/test_helper"
require "time"

class UtilTest < Test::Unit::TestCase
  include Tweetwine

  context "The module" do
    should "colorize a string" do
      assert_equal "\033[31mfoo bar\033[0m", Util.colorize(:red, "foo bar")
    end

    should "colorize selected parts of a string" do
      assert_equal "foo \033[31mbar\033[0m baz", Util.colorize(:red, "foo bar baz", /bar/)
    end

    should "humanize time difference" do
      assert_equal [1,  "sec"], Util.humanize_time_diff(Time.parse("2009-01-01 00:00:59").to_s, Time.parse("2009-01-01 00:01:00"))
      assert_equal [0,  "sec"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:00"))
      assert_equal [1,  "sec"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:01"))
      assert_equal [59, "sec"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:59"))
      assert_equal [59, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 01:59"))
      assert_equal [59, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00:30").to_s, Time.parse("2009-01-01 01:59:00"))
      assert_equal [57, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:00"))
      assert_equal [56, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:01:31").to_s, Time.parse("2009-01-01 01:58:00"))
      assert_equal [57, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:29"))
      assert_equal [58, "min"], Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:30"))
      assert_equal [1,  "hour"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 02:00"))
      assert_equal [1,  "hour"], Util.humanize_time_diff(Time.parse("2009-01-01 02:00").to_s, Time.parse("2009-01-01 01:00"))
      assert_equal [2,  "hours"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 03:00"))
      assert_equal [1,  "day"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-02 03:00"))
      assert_equal [2,  "days"], Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-03 03:00"))
    end
  end
end