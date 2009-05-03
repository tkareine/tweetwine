require File.dirname(__FILE__) << "/test_helper"
require "json"

module Tweetwine

class ClientTest < Test::Unit::TestCase
  context "Upon initializing a client" do
    should "raise exception when no authentication data is given" do
      assert_raises(ArgumentError) { Client.new({}) }
      assert_raises(ArgumentError) { Client.new({ :password => "bar" }) }
      assert_raises(ArgumentError) { Client.new({ :username => "", :password => "bar" }) }
    end

    should "use default num of statuses if not configured otherwise" do
      @client = Client.new({ :username => "foo", :password => "bar" })
      assert_equal Client::DEFAULT_NUM_STATUSES, @client.num_statuses
    end

    should "use configured num of statuses if in allowed range" do
      @client = Client.new({ :username => "foo", :password => "bar", :num_statuses => 12 })
      assert_equal 12, @client.num_statuses
    end

    should "raise an exception for configured num of statuses if not in allowed range" do
      assert_raises(ArgumentError) { Client.new({ :username => "foo", :password => "bar", :num_statuses => Client::MAX_NUM_STATUSES + 1 }) }
    end
  end

  context "A client" do
    setup do
      @client = Client.new({ :username => "foo", :password => "bar" })
      @io = mock()
      @client.instance_variable_set(:@io, @io)
    end

    should "raise ClientError for invalid request" do
      RestClient.expects(:get) \
                .with("https://foo:bar@twitter.com/statuses/friends_timeline.json?count=20") \
                .raises(RestClient::Unauthorized)
      assert_raises(ClientError) { @client.home }
    end

    should "fetch friends' statuses (home view)" do
      statuses = [
        {
          "created_at" => Time.at(1).to_s,
          "user" => { "username" => "zanzibar" },
          "text" => "wassup?"
        },
        {
          "created_at" => Time.at(2).to_s,
          "user" => { "username" => "lulzwoo" },
          "text" => "nuttin"
        }
      ]
      RestClient.expects(:get) \
                .with("https://foo:bar@twitter.com/statuses/friends_timeline.json?count=20") \
                .returns(statuses.to_json)
      @io.expects(:show_statuses).with(statuses)
      @client.home
    end

    should "fetch mentions" do
      statuses = [
        {
          "created_at" => Time.at(1).to_s,
          "in_reply_to_screen_name" => "foo",
          "user" => { "username" => "zanzibar" },
          "text" => "wassup, @foo?"
        },
        {
          "created_at" => Time.at(2).to_s,
          "in_reply_to_screen_name" => "foo",
          "user" => { "username" => "lulzwoo" },
          "text" => "@foo, doing nuttin"
        }
      ]
      RestClient.expects(:get) \
                .with("https://foo:bar@twitter.com/statuses/mentions.json?count=20") \
                .returns(statuses.to_json)
      @io.expects(:show_statuses).with(statuses)
      @client.mentions
    end

    should "fetch a specific user's statuses, with the user identified by given argument" do
      statuses = [
        {
          "created_at" => Time.at(1).to_s,
          "user" => { "username" => "zanzibar" },
          "text" => "wassup?"
        }
      ]
      RestClient.expects(:get) \
                .with("https://foo:bar@twitter.com/statuses/user_timeline/zanzibar.json?count=20") \
                .returns(statuses.to_json)
      @io.expects(:show_statuses).with(statuses)
      @client.user("zanzibar")
    end

    should "fetch a specific user's statuses, with the user being the authenticated user itself when given no argument" do
      statuses = [
        {
          "created_at" => Time.at(1).to_s,
          "user" => { "username" => "foo" },
          "text" => "wassup?"
        }
      ]
      RestClient.expects(:get) \
                .with("https://foo:bar@twitter.com/statuses/user_timeline/foo.json?count=20") \
                .returns(statuses.to_json)
      @io.expects(:show_statuses).with(statuses)
      @client.user
    end

    should "post a status update, when positive confirmation" do
      status = {
        "created_at" => Time.at(1).to_s,
        "user" => { "username" => "foo" },
        "text" => "wondering about"
      }
      RestClient.expects(:post) \
                .with("https://foo:bar@twitter.com/statuses/update.json", {:status => "wondering about"}) \
                .returns(status.to_json)
      @io.expects(:confirm).with("Really send?").returns(true)
      @io.expects(:info).with("Sent status update.\n\n")
      @io.expects(:show_statuses).with([status])
      @client.update("wondering about")
    end

    should "cancel a status update, when negative confirmation" do
      RestClient.expects(:post).never
      @io.expects(:confirm).with("Really send?").returns(false)
      @io.expects(:info).with("Cancelled.")
      @io.expects(:show_statuses).never
      @client.update("wondering about")
    end

    should "truncate a status update too long and warn the user" do
      long_status_update = "x aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq rrr sss ttt uuu vvv www xxx yyy zzz 111 222 333 444 555 666 777 888 999 000"
      truncated_status_update = "x aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq rrr sss ttt uuu vvv www xxx yyy zzz 111 222 333 444 555 666 777 888 99"
      status = {
        "created_at" => Time.at(1).to_s,
        "user" => { "username" => "foo" },
        "text" => truncated_status_update
      }

      RestClient.expects(:post) \
                .with("https://foo:bar@twitter.com/statuses/update.json", {:status => truncated_status_update}) \
                .returns(status.to_json)
      @io.expects(:warn).with("Update will be truncated: #{truncated_status_update}")
      @io.expects(:confirm).with("Really send?").returns(true)
      @io.expects(:info).with("Sent status update.\n\n")
      @io.expects(:show_statuses).with([status])
      @client.update(long_status_update)
    end
  end
end

end
