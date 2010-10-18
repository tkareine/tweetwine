# coding: utf-8

require "test_helper"

module Tweetwine::Test

class OAuthTest < UnitTestCase
  context "for initialization" do
    should "raise exception if not given OAuth consumer key" do
      assert_raise(RequiredOptionError) do
        OAuth.new({:consumer_secret => 2, :access_key => 3, :access_secret => 4})
      end
    end

    should "raise exception if not given OAuth consumer secret" do
      assert_raise(RequiredOptionError) do
        OAuth.new({:consumer_key => 1, :access_key => 3, :access_secret => 4})
      end
    end

    should "raise exception if not given OAuth access key" do
      assert_raise(RequiredOptionError) do
        OAuth.new({:consumer_key => 1, :consumer_secret => 2, :access_secret => 4})
      end
    end

    should "raise exception if not given OAuth access secret" do
      assert_raise(RequiredOptionError) do
        OAuth.new({:consumer_key => 1, :consumer_secret => 2, :access_key => 3})
      end
    end
  end
end

end
