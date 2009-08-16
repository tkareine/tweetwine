require File.dirname(__FILE__) << "/test_helper"

module Tweetwine

class OptionsTest < Test::Unit::TestCase
  context "Options" do
    should "get the value corresponding to a key or nil (the default value)" do
      assert_equal "alpha", Options.new({:a => "alpha"})[:a]
      assert_equal nil, Options.new({})[:a]
    end

    should "require missing value (a value that is nil)" do
      assert_equal "alpha", Options.new({:a => "alpha"}).require(:a)
      assert_raises(RuntimeError) { Options.new({}).require(:a) }
    end
  end
end

end