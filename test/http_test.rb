# coding: utf-8

require "test_helper"
require "rest_client"

class Object
  def sleep(timeout); end   # speed up tests
end

module Tweetwine

class HttpModuleTest < TweetwineTestCase
  setup do
    Http.proxy = "http://proxy.net:8080"
  end

  should "pass HTTP proxy configuration to RestClient" do
    assert_equal "http://proxy.net:8080", RestClient.proxy
  end

  teardown do
    Http.proxy = nil
  end
end

class HttpClientTest < TweetwineTestCase
  setup do
    mock_ui
    @client = Http::Client.new
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

  [Errno::ECONNRESET, RestClient::RequestTimeout].each do |error_class|
    should "retry connection upon connection reset, case #{error_class}" do
      retrying_calls = sequence("Retrying Client calls")
      RestClient.expects(:get).with("https://moderate.traffic.org").in_sequence(retrying_calls).raises(error_class)
      RestClient.expects(:get).with("https://moderate.traffic.org").in_sequence(retrying_calls)
      @ui.expects(:warn).with("Could not connect -- retrying in 4 seconds")
      @client.get("https://moderate.traffic.org")
    end

    should "retry connection a maximum of certain number of times, case #{error_class}" do
      retrying_calls = sequence("Retrying Client calls")
      io_calls = sequence("IO")
      (Http::Client::MAX_RETRIES + 1).times do
        RestClient.expects(:get).with("https://unresponsive.org").in_sequence(retrying_calls).raises(error_class)
      end
      Http::Client::MAX_RETRIES.times do
        @ui.expects(:warn).in_sequence(io_calls)
      end
      assert_raise(HttpError) { @client.get("https://unresponsive.org") }
    end
  end
end

class HttpResourceTest < TweetwineTestCase
  setup do
    mock_ui
    @wrapped = mock
    @resource = Http::Resource.new(@wrapped)
  end

  should "allow wrapping RestClient::Resource#get" do
    @wrapped.expects(:get).with("https://site.org")
    @resource.get("https://site.org")
  end

  should "allow wrapping RestClient::Resource#post" do
    @wrapped.expects(:post).with("https://site.org", { :key => "value" })
    @resource.post("https://site.org", { :key => "value" })
  end

  should "allow nesting of URL parts" do
    site_resource = mock
    page_resource = mock
    @wrapped.expects(:[]).with("https://site.org/").returns(site_resource)
    site_resource.expects(:[]).with("page").returns(page_resource)
    page_resource.expects(:get)
    site = @resource["https://site.org/"]
    page = site["page"]
    page.get
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

  [Errno::ECONNRESET, RestClient::RequestTimeout].each do |error_class|
    should "retry connection upon connection reset, case #{error_class}" do
      retrying_calls = sequence("Retrying Resource calls")
      @wrapped.expects(:get).in_sequence(retrying_calls).raises(error_class)
      @wrapped.expects(:get).in_sequence(retrying_calls)
      @ui.expects(:warn).with("Could not connect -- retrying in 4 seconds")
      @resource.get
    end

    should "retry connection a maximum of certain number of times, case #{error_class}" do
      retrying_calls = sequence("Retrying Resource calls")
      io_calls = sequence("IO")
      (Http::Resource::MAX_RETRIES + 1).times do
        @wrapped.expects(:get).in_sequence(retrying_calls).raises(error_class)
      end
      Http::Resource::MAX_RETRIES.times do
        @ui.expects(:warn).in_sequence(io_calls)
      end
      assert_raise(HttpError) { @resource.get }
    end
  end
end

end
