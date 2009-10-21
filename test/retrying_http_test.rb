require "test_helper"
require "rest_client"

class Object
  def sleep(timeout); end   # speed up tests
end

module Tweetwine
module RetryingHttp

class ClientTest < Test::Unit::TestCase
  context "A Client instance" do
    setup do
      @io = mock()
      @client = Client.new(@io)
    end

    should "wrap RestClient.get" do
      RestClient.expects(:get).with("https://site.org")
      @client.get("https://site.org")
    end

    should "wrap RestClient.post" do
      RestClient.expects(:post).with("https://site.org", { :key => "value" })
      @client.post("https://site.org", { :key => "value" })
    end

    should "raise HttpError for an invalid request" do
      RestClient.expects(:get).with("https://charlie:42@authorization.org").raises(RestClient::Unauthorized)
      assert_raise(HttpError) { @client.get("https://charlie:42@authorization.org") }
    end

    should "raise HttpError when connection cannot be established" do
      RestClient.expects(:get).with("https://unreachable.org").raises(Errno::ECONNABORTED)
      assert_raise(HttpError) { @client.get("https://unreachable.org") }
    end

    should "raise HttpError when host cannot be resolved" do
      RestClient.expects(:get).with("https://unresolved.org").raises(SocketError)
      assert_raise(HttpError) { @client.get("https://unresolved.org") }
    end

    should "retry connection upon connection reset" do
      retrying_calls = sequence("Retrying Client calls")
      RestClient.expects(:get).with("https://moderate.traffic.org").in_sequence(retrying_calls).raises(Errno::ECONNRESET)
      RestClient.expects(:get).with("https://moderate.traffic.org").in_sequence(retrying_calls)
      @io.expects(:warn).with("Could not connect -- retrying in 4 seconds")
      @client.get("https://moderate.traffic.org")
    end

    should "retry connection a maximum of certain number of times" do
      retrying_calls = sequence("Retrying Client calls")
      io_calls = sequence("IO")
      Client::MAX_RETRIES.times do
        RestClient.expects(:get).with("https://unresponsive.org").in_sequence(retrying_calls).raises(Errno::ECONNRESET)
      end
      (Client::MAX_RETRIES - 1).times do
        @io.expects(:warn).in_sequence(io_calls)
      end
      assert_raise(HttpError) { @client.get("https://unresponsive.org") }
    end

    should "return a resource with IO inherited from the client" do
      resource = @client.as_resource("http://foo.bar")
      assert_equal(@io, resource.io)
    end
  end
end

class ResourceTest < Test::Unit::TestCase
  context "A Resource instance" do
    setup do
      @io = mock()
      @wrapped = mock()
      @resource = Resource.new(@wrapped)
      @resource.io = @io
    end

    should "allow wrapping RestClient::Resource#get" do
      @wrapped.expects(:get).with("https://site.org")
      @resource.get("https://site.org")
    end

    should "allow wrapping RestClient::Resource#post" do
      @wrapped.expects(:post).with("https://site.org", { :key => "value" })
      @resource.post("https://site.org", { :key => "value" })
    end

    should "raise HttpError for an invalid request" do
      @wrapped.expects(:get).raises(RestClient::Unauthorized)
      assert_raise(HttpError) { @resource.get }
    end

    should "raise HttpError when connection cannot be established" do
      @wrapped.expects(:get).raises(Errno::ECONNABORTED)
      assert_raise(HttpError) { @resource.get }
    end

    should "raise HttpError when host cannot be resolved" do
      @wrapped.expects(:get).raises(SocketError)
      assert_raise(HttpError) { @resource.get }
    end

    should "retry connection upon connection reset" do
      retrying_calls = sequence("Retrying Resource calls")
      @wrapped.expects(:get).in_sequence(retrying_calls).raises(Errno::ECONNRESET)
      @wrapped.expects(:get).in_sequence(retrying_calls)
      @io.expects(:warn).with("Could not connect -- retrying in 4 seconds")
      @resource.get
    end

    should "retry connection a maximum of certain number of times" do
      retrying_calls = sequence("Retrying Resource calls")
      io_calls = sequence("IO")
      Resource::MAX_RETRIES.times do
        @wrapped.expects(:get).in_sequence(retrying_calls).raises(Errno::ECONNRESET)
      end
      (Resource::MAX_RETRIES - 1).times do
        @io.expects(:warn).in_sequence(io_calls)
      end
      assert_raise(HttpError) { @resource.get }
    end
  end
end

end
end
