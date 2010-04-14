# coding: utf-8

require "test_helper"

module Tweetwine

class OptionsTest < Test::Unit::TestCase
  context "An Options instance" do
    should "get the value corresponding to a key or nil (the default value)" do
      assert_equal "alpha", Options.new({:a => "alpha"})[:a]
      assert_equal nil, Options.new({})[:a]
    end

    context "for requiring options" do
      should "raise ArgumentError if there's no value for the required option (a value that is nil)" do
        assert_equal "alpha", Options.new({:a => "alpha"}).require(:a)
        assert_raise(ArgumentError) { Options.new({}).require(:a) }
      end

      should "indicate the required option upon failure" do
        error = nil
        begin
          Options.new({}).require(:a)
          flunk "should have raised ArgumentError"
        rescue ArgumentError => e
          error = e
        end
        assert_equal("Option a is required", e.to_s)
      end

      should "indicate the required option upon failure, with optional error source" do
        error = nil
        begin
          Options.new({}, "test options").require(:a)
          flunk "should have raised ArgumentError"
        rescue ArgumentError => e
          error = e
        end
        assert_equal("Option a is required for test options", e.to_s)
      end
    end
  end
end

end