require "test_helper"
require "rest_client"

module Tweetwine

class RestClientWrapperTest < Test::Unit::TestCase
  context "A RestClientWrapper instance" do
    setup do
      @io = mock()
      @rest_client = RestClientWrapper.new(@io)
    end

    should "raise ClientError for an invalid request" do
      RestClient.expects(:get) \
                .with("https://secret:agent@hushhush.net") \
                .raises(RestClient::Unauthorized)
      assert_raise(ClientError) { @rest_client.get("https://secret:agent@hushhush.net") }
    end

    should "raise ClientError when connection cannot be established" do
      RestClient.expects(:get) \
                .with("http://www.invalid.net") \
                .raises(Errno::ECONNRESET)
      assert_raise(ClientError) { @rest_client.get("http://www.invalid.net") }
    end

    should "raise ClientError when host cannot be resolved" do
      RestClient.expects(:get) \
                .with("http://unknown.net") \
                .raises(SocketError)
      assert_raise(ClientError) { @rest_client.get("http://unknown.net") }
    end
  end
end

end
