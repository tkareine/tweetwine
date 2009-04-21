require File.dirname(__FILE__) << "/test_helper"

class ConfigTest < Test::Unit::TestCase
  include Tweetwine

  TESTFILE = File.dirname(__FILE__) << "/test_config.yaml"

  context "A config before loading" do
    should "not allow initialization with new" do
      assert_raise(NoMethodError) { Tweetwine::Config.new(TESTFILE) }
    end

    should "allow initialization with load" do
      assert_nothing_raised { Tweetwine::Config.load(TESTFILE) }
    end
  end

  context "A config with loaded example data" do
    setup do
      @config = Tweetwine::Config.load(TESTFILE)
    end

    should "give the value for a configured property" do
      assert_equal "foo", @config.username
    end

    should "report configured property as existing" do
      assert_equal true, @config.username?
    end

    should "give nil for unconfigured property" do
      assert_nil @config.nonexisting_property
    end

    should "report configured property as non-existing" do
      assert_equal false, @config.nonexisting_property?
    end
  end
end
