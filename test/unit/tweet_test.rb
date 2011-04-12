# coding: utf-8

require 'unit/helper'
require 'unit/tweet_helper'

module Tweetwine::Test

class TweetTest < UnitTest
  include TweetHelper

  describe "for initialization" do
    it "raises exception if from user field is not found" do
      assert_raises(ArgumentError) { create_tweet(:from_user => nil) }
    end
  end

  describe "for equality" do
    it "equals to another tweet with same content" do
      status = 'foo'
      first  = create_tweet(:status => status)
      second = create_tweet(:status => status)
      assert_equal first, second
    end

    it "does not equal to another tweet with different content" do
      first  = create_tweet(:status => 'ahem')
      second = create_tweet(:status => 'hmph')
      refute_equal first, second
    end
  end

  describe "for handling regular tweet" do
    before do
      @status = 'lurking'
      @tweet = create_tweet(:status => @status)
    end

    it "detects tweet as not retweet" do
      assert_equal false, @tweet.retweet?
    end

    it "does not have retweeting user" do
      assert_nil @tweet.rt_user
    end

    it "has originating user field" do
      assert_equal(DEFAULT_FIELD_VALUES[:from_user], @tweet.from_user)
    end

    it "detects tweet as not being a reply" do
      assert_equal false, @tweet.reply?
    end

    it "has no destination user" do
      assert_nil @tweet.to_user
    end

    it "detects having creation timestamp" do
      assert_equal true, @tweet.timestamped?
    end

    it "has creation timestamp" do
      assert_equal Time.parse(DEFAULT_FIELD_VALUES[:created_at]), @tweet.created_at
    end

    it "detects having status" do
      assert_equal true, @tweet.status?
    end

    it "has status" do
      assert_equal @status, @tweet.status
    end
  end

  describe "for handling replying tweet" do
    before do
      @to_user = 'jacko'
      @tweet = create_tweet(:to_user => @to_user)
    end

    it "detects tweet as being a reply" do
      assert_equal true, @tweet.reply?
    end

    it "has destination user" do
      assert_equal @to_user, @tweet.to_user
    end
  end

  describe "for handling retweet" do
    before do
      @rt_user = 'jonathan'
      @status = 'tweet worth retweeting'
      @tweet = create_tweet(:rt_user => @rt_user, :status => @status)
    end

    it "detects tweet as retweet" do
      assert_equal true, @tweet.retweet?
    end

    it "has retweeting user" do
      assert_equal @rt_user, @tweet.rt_user
    end

    it "has originating user" do
      assert_equal DEFAULT_FIELD_VALUES[:from_user], @tweet.from_user
    end

    it "detects having creation timestamp of the original tweet" do
      assert_equal true, @tweet.timestamped?
    end

    it "has creation timestamp of the original tweet" do
      assert_equal Time.parse(DEFAULT_FIELD_VALUES[:created_at]), @tweet.created_at
    end

    it "detects having status of the original tweet" do
      assert_equal true, @tweet.status?
    end

    it "has status of the original tweet" do
      assert_equal @status, @tweet.status
    end
  end

  describe "for handling tweet with just user info" do
    before do
      @tweet = create_tweet(:to_user => nil, :status => nil, :created_at => nil)
    end

    it "detects tweet as not retweet" do
      assert_equal false, @tweet.retweet?
    end

    it "has originating user field" do
      assert_equal(DEFAULT_FIELD_VALUES[:from_user], @tweet.from_user)
    end

    it "detects tweet as not being a reply" do
      assert_equal false, @tweet.reply?
    end

    it "detects having no creation timestamp" do
      assert_equal false, @tweet.timestamped?
    end

    it "detects having no status" do
      assert_equal false, @tweet.status?
    end
  end
end

end
