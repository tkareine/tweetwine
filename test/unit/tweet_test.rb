# coding: utf-8

require 'unit/helper'
require 'unit/tweet_helper'

module Tweetwine::Test

class TweetTest < UnitTestCase
  include TweetHelper

  context "for initialization" do
    should "raise exception if from user field is not found" do
      assert_raise(ArgumentError) { create_tweet(:from_user => nil) }
    end
  end

  context "for equality" do
    should "equal to another tweet with same content" do
      status = 'foo'
      first  = create_tweet(:status => status)
      second = create_tweet(:status => status)
      assert_equal first, second
    end

    should "not equal to another tweet with different content" do
      first  = create_tweet(:status => 'ahem')
      second = create_tweet(:status => 'hmph')
      assert_not_equal first, second
    end
  end

  context "for handling regular tweet" do
    setup do
      @status = 'lurking'
      @tweet = create_tweet(:status => @status)
    end

    should "detect tweet as not retweet" do
      assert_equal false, @tweet.retweet?
    end

    should "not have retweeting user" do
      assert_nil @tweet.rt_user
    end

    should "have originating user field" do
      assert_equal(DEFAULT_FIELD_VALUES[:from_user], @tweet.from_user)
    end

    should "detect tweet as not being a reply" do
      assert_equal false, @tweet.reply?
    end

    should "have no destination user" do
      assert_nil @tweet.to_user
    end

    should "detect having creation timestamp" do
      assert_equal true, @tweet.timestamped?
    end

    should "have creation timestamp" do
      assert_equal Time.parse(DEFAULT_FIELD_VALUES[:created_at]), @tweet.created_at
    end

    should "detect having status" do
      assert_equal true, @tweet.status?
    end

    should "have status" do
      assert_equal @status, @tweet.status
    end
  end

  context "for handling replying tweet" do
    setup do
      @to_user = 'jacko'
      @tweet = create_tweet(:to_user => @to_user)
    end

    should "detect tweet as being a reply" do
      assert_equal true, @tweet.reply?
    end

    should "have destination user" do
      assert_equal @to_user, @tweet.to_user
    end
  end

  context "for handling retweet" do
    setup do
      @rt_user = 'jonathan'
      @status = 'tweet worth retweeting'
      @tweet = create_tweet(:rt_user => @rt_user, :status => @status)
    end

    should "detect tweet as retweet" do
      assert_equal true, @tweet.retweet?
    end

    should "have retweeting user" do
      assert_equal @rt_user, @tweet.rt_user
    end

    should "have originating user" do
      assert_equal DEFAULT_FIELD_VALUES[:from_user], @tweet.from_user
    end

    should "detect having creation timestamp of the original tweet" do
      assert_equal true, @tweet.timestamped?
    end

    should "have creation timestamp of the original tweet" do
      assert_equal Time.parse(DEFAULT_FIELD_VALUES[:created_at]), @tweet.created_at
    end

    should "detect having status of the original tweet" do
      assert_equal true, @tweet.status?
    end

    should "have status of the original tweet" do
      assert_equal @status, @tweet.status
    end
  end

  context "for handling tweet with just user info" do
    setup do
      @tweet = create_tweet(:to_user => nil, :status => nil, :created_at => nil)
    end

    should "detect tweet as not retweet" do
      assert_equal false, @tweet.retweet?
    end

    should "have originating user field" do
      assert_equal(DEFAULT_FIELD_VALUES[:from_user], @tweet.from_user)
    end

    should "detect tweet as not being a reply" do
      assert_equal false, @tweet.reply?
    end

    should "detect having no creation timestamp" do
      assert_equal false, @tweet.timestamped?
    end

    should "detect having no status" do
      assert_equal false, @tweet.status?
    end
  end
end

end
