require File.dirname(__FILE__) << "/test_helper"
require "json"

module Tweetwine

class ClientTest < Test::Unit::TestCase
  context "Upon initializing a client" do
    should "raise exception when no authentication data is given" do
      assert_raises(ArgumentError) { Client.new({}) }
      assert_raises(ArgumentError) { Client.new({ :password => "bar" }) }
      assert_raises(ArgumentError) { Client.new({ :username => "", :password => "bar" }) }
      assert_nothing_raised { Client.new({ :username => "foo", :password => "bar" }) }
    end

    should "use default number of statuses if not configured otherwise" do
      @client = Client.new({ :username => "foo", :password => "bar" })
      assert_equal Client::DEFAULT_NUM_STATUSES, @client.num_statuses
    end

    should "use configured number of statuses if in allowed range" do
      @client = Client.new({ :username => "foo", :password => "bar", :num_statuses => 12 })
      assert_equal 12, @client.num_statuses
    end

    should "raise an exception for configured number of statuses if not in allowed range" do
      assert_raises(ArgumentError) { Client.new({ :username => "foo", :password => "bar", :num_statuses => 0 }) }
    end

    should "use default page number if not configured otherwise" do
      @client = Client.new({ :username => "foo", :password => "bar" })
      assert_equal Client::DEFAULT_PAGE_NUM, @client.page_num
    end

    should "use configured page number if in allowed range" do
      @client = Client.new({ :username => "foo", :password => "bar", :page_num => 12 })
      assert_equal 12, @client.page_num
    end

    should "raise an exception for configured page number if not in allowed range" do
      assert_raises(ArgumentError) { Client.new({ :username => "foo", :password => "bar", :page_num => 0 }) }
    end
  end

  context "A client" do
    setup do
      @client = Client.new({ :username => "foo", :password => "bar" })
      @io = mock()
      @client.instance_variable_set(:@io, @io)
      @query_params = "count=#{Client::DEFAULT_NUM_STATUSES}&page=#{Client::DEFAULT_PAGE_NUM}"
    end

    should "raise ClientError for invalid request" do
      RestClient.expects(:get) \
                .with("https://foo:bar@twitter.com/statuses/friends_timeline.json?#{@query_params}") \
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
                .with("https://foo:bar@twitter.com/statuses/friends_timeline.json?#{@query_params}") \
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
                .with("https://foo:bar@twitter.com/statuses/mentions.json?#{@query_params}") \
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
                .with("https://foo:bar@twitter.com/statuses/user_timeline/zanzibar.json?#{@query_params}") \
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
                .with("https://foo:bar@twitter.com/statuses/user_timeline/foo.json?#{@query_params}") \
                .returns(statuses.to_json)
      @io.expects(:show_statuses).with(statuses)
      @client.user
    end

    should "post a status update via argument, when positive confirmation" do
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

    should "post a status update via prompt, when positive confirmation" do
      status = {
        "created_at" => Time.at(1).to_s,
        "user" => { "username" => "foo" },
        "text" => "wondering about"
      }
      RestClient.expects(:post) \
                .with("https://foo:bar@twitter.com/statuses/update.json", {:status => "wondering about"}) \
                .returns(status.to_json)
      @io.expects(:prompt).with("Status update").returns("wondering about")
      @io.expects(:confirm).with("Really send?").returns(true)
      @io.expects(:info).with("Sent status update.\n\n")
      @io.expects(:show_statuses).with([status])
      @client.update
    end

    should "cancel a status update via argument, when negative confirmation" do
      RestClient.expects(:post).never
      @io.expects(:confirm).with("Really send?").returns(false)
      @io.expects(:info).with("Cancelled.")
      @io.expects(:show_statuses).never
      @client.update("wondering about")
    end

    should "cancel a status update via prompt, when negative confirmation" do
      RestClient.expects(:post).never
      @io.expects(:prompt).with("Status update").returns("wondering about")
      @io.expects(:confirm).with("Really send?").returns(false)
      @io.expects(:info).with("Cancelled.")
      @io.expects(:show_statuses).never
      @client.update
    end

    should "cancel a status update via argument, when empty status" do
      RestClient.expects(:post).never
      @io.expects(:confirm).never
      @io.expects(:info).with("Cancelled.")
      @io.expects(:show_statuses).never
      @client.update("")
    end

    should "cancel a status update via prompt, when empty status" do
      RestClient.expects(:post).never
      @io.expects(:prompt).with("Status update").returns("")
      @io.expects(:confirm).never
      @io.expects(:info).with("Cancelled.")
      @io.expects(:show_statuses).never
      @client.update
    end

    should "truncate a status update with too long argument and warn the user" do
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
      @io.expects(:warn).with("Status will be truncated: #{truncated_status_update}")
      @io.expects(:confirm).with("Really send?").returns(true)
      @io.expects(:info).with("Sent status update.\n\n")
      @io.expects(:show_statuses).with([status])
      @client.update(long_status_update)
    end
  end
end

end
