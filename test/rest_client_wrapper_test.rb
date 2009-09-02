require "test_helper"
require "rest_client"

module Tweetwine

class RestClientWrapperTest < Test::Unit::TestCase
  context "A rest client wrapper" do
    should "raise ClientError for an invalid request" do
      RestClient.expects(:get) \
                .with("https://secret:agent@hushhush.net") \
                .raises(RestClient::Unauthorized)
      assert_raise(ClientError) { RestClientWrapper.get("https://secret:agent@hushhush.net") }
    end

    should "raise ClientError when connection cannot be established" do
      RestClient.expects(:get) \
                .with("http://www.invalid.net") \
                .raises(Errno::ECONNRESET)
      assert_raise(ClientError) { RestClientWrapper.get("http://www.invalid.net") }
    end

    should "raise ClientError when host cannot be resolved" do
      RestClient.expects(:get) \
                .with("http://unknown.net") \
                .raises(SocketError)
      assert_raise(ClientError) { RestClientWrapper.get("http://unknown.net") }
    end
  end
end

end
