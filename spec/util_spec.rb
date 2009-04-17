require File.dirname(__FILE__) << "/spec_helper"
require "time"

include Tweetwine

describe Util do
  it "should humanize time difference" do
    Util.humanize_time_diff(Time.parse("2009-01-01 00:00:59").to_s, Time.parse("2009-01-01 00:01:00")).should == [1, "sec"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:00")).should == [0, "sec"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:01")).should == [1, "sec"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:00:00").to_s, Time.parse("2009-01-01 01:00:59")).should == [59, "sec"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 01:59")).should == [59, "min"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:00:30").to_s, Time.parse("2009-01-01 01:59:00")).should == [59, "min"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:00")).should == [57, "min"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:01:31").to_s, Time.parse("2009-01-01 01:58:00")).should == [56, "min"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:29")).should == [57, "min"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:01:00").to_s, Time.parse("2009-01-01 01:58:30")).should == [58, "min"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 02:00")).should == [1, "hour"]
    Util.humanize_time_diff(Time.parse("2009-01-01 02:00").to_s, Time.parse("2009-01-01 01:00")).should == [1, "hour"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-01 03:00")).should == [2, "hours"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-02 03:00")).should == [1, "day"]
    Util.humanize_time_diff(Time.parse("2009-01-01 01:00").to_s, Time.parse("2009-01-03 03:00")).should == [2, "days"]
  end
end