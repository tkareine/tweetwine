require File.dirname(__FILE__) << "/spec_helper"

testfile = File.dirname(__FILE__) << "/test_config.yaml"

describe Config, "before loading" do
  it "should not allow initialization with new" do
    lambda { Tweetwine::Config.new(testfile) }.should raise_error
  end

  it "should allow initialization with load" do
    lambda { Tweetwine::Config.load(testfile) }.should_not raise_error
  end
end

describe Config, "with loaded example data" do
  before(:each) do
    @config = Tweetwine::Config.load(testfile)
  end

  it "should give the value for a configured property" do
    @config.username.should == "foo"
  end

  it "should report configured property as existing" do
    @config.username?.should be_true
  end

  it "should give nil for unconfigured property" do
    @config.nonexisting_property.should be_nil
  end

  it "should report configured property as non-existing" do
    @config.nonexisting_property?.should be_false
  end
end