require File.dirname(__FILE__) << "/test_helper"
require "json"

class ClientTest < Test::Unit::TestCase
  include Tweetwine

  context "A client" do
    setup do
      @client = Client.new({ :username => "foo", :password => "bar" })
    end

    should "fetch friends' status timeline" do
      statuses = [
        {
          :created_at => Time.at(1),
          :user => { :username => "zanzibar" },
          :text => "wassup?"
        },
        {
          :created_at => Time.at(2),
          :user => { :username => "lulzwoo" },
          :text => "nuttin"
        }
      ]

      RestClient.expects(:get) \
                .with("https://foo:bar@twitter.com/statuses/friends_timeline.json?count=20") \
                .returns(statuses.to_json)
      @client.expects(:print_statuses)
      @client.friends
    end

    should "fetch user's status timeline" do
      statuses = [
        {
          :created_at => Time.at(1),
          :user => { :username => "zanzibar" },
          :text => "wassup?"
        },
      ]

      RestClient.expects(:get) \
                .with("https://foo:bar@twitter.com/statuses/user_timeline/zanzibar.json?count=20") \
                .returns(statuses.to_json)
      @client.expects(:print_statuses)
      @client.user("zanzibar")
    end

    should "post a new status update with confirmation" do
      statuses = [
        {
          :created_at => Time.at(1),
          :user => { :username => "zanzibar" },
          :text => "wassup?"
        },
      ]

      RestClient.expects(:post) \
                .with("https://foo:bar@twitter.com/statuses/update.json", {:status => "wondering about"}) \
                .returns(statuses.to_json)
      @client.expects(:print_statuses)
      @client.expects(:confirm_user_action).returns(true)
      @client.msg("wondering about")
    end
  end
end

