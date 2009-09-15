require "test_helper"
require "rest_client"

class Object
  def sleep(timeout); end   # speed up tests
end

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
                .raises(Errno::ECONNABORTED)
      assert_raise(ClientError) { @rest_client.get("http://www.invalid.net") }
    end

    should "raise ClientError when host cannot be resolved" do
      RestClient.expects(:get) \
                .with("http://unknown.net") \
                .raises(SocketError)
      assert_raise(ClientError) { @rest_client.get("http://unknown.net") }
    end

    should "retry connection upon connection reset" do
      rest_client_calls = sequence("RestClient")
      RestClient.expects(:get) \
                .with("http://www.heavilyloaded.net") \
                .in_sequence(rest_client_calls) \
                .raises(Errno::ECONNRESET)
      RestClient.expects(:get) \
                .with("http://www.heavilyloaded.net") \
                .in_sequence(rest_client_calls)
      @io.expects(:warn).with("Could not connect -- retrying in 4 seconds")
      @rest_client.get("http://www.heavilyloaded.net")
    end

    should "retry connection a maximum of certain number of times" do
      rest_client_calls = sequence("RestClient")
      io_calls = sequence("IO")
      RestClientWrapper::MAX_RETRIES.times do
        RestClient.expects(:get) \
                  .with("http://www.heavilyloaded.net") \
                  .in_sequence(rest_client_calls) \
                  .raises(Errno::ECONNRESET)
      end
      (RestClientWrapper::MAX_RETRIES - 1).times do
        @io.expects(:warn).in_sequence(io_calls)
      end
      assert_raise(ClientError) { @rest_client.get("http://www.heavilyloaded.net") }
    end
  end
end

end
