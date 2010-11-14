# coding: utf-8

require "unit_helper"

module Tweetwine::Test

class HttpTest < UnitTestCase
  RESPONSE_BODY = "resp"
  CUSTOM_HEADERS = {'X-Custom' => 'true'}
  SITE_URL = "https://site.org"
  LATEST_ARTICLES_URL = "#{SITE_URL}/articles/latest"
  LATEST_ARTICLES_URL_SORTED = "#{LATEST_ARTICLES_URL}?sort=date"
  NEW_ARTICLE_URL = "#{SITE_URL}/articles/new"
  PAYLOAD = {:msg => 'gloomy night'}

  setup do
    stub_sleep
    mock_ui
    @client = Http::Client.new
  end

  teardown do
    restore_sleep
  end

  %w{http https}.each do |scheme|
    should "support #{scheme} scheme" do
      url = "#{scheme}://site.org/"
      stub_request(:get, url)
      @client.get(url)
      assert_requested(:get, url)
    end
  end

  should "return response body when successful response" do
    stub_request(:get, LATEST_ARTICLES_URL).to_return(:body => RESPONSE_BODY)
    assert_equal(RESPONSE_BODY, @client.get(LATEST_ARTICLES_URL))
  end

  should "send GET request with query parameters and custom headers" do
    stub_request(:get, LATEST_ARTICLES_URL_SORTED)
    @client.get(LATEST_ARTICLES_URL_SORTED, CUSTOM_HEADERS)
    assert_requested(:get, LATEST_ARTICLES_URL_SORTED, :headers => CUSTOM_HEADERS)
  end

  should "send POST request with payload and custom headers" do
    stub_request(:post, NEW_ARTICLE_URL).with(:body => PAYLOAD, :headers => CUSTOM_HEADERS)
    @client.post(NEW_ARTICLE_URL, PAYLOAD, CUSTOM_HEADERS)
    assert_requested(:post, NEW_ARTICLE_URL, :body => PAYLOAD, :headers => CUSTOM_HEADERS)
  end

  should "store response code and message in HttpError when failed response" do
    code, message = 501, 'Not Implemented'
    stub_request(:get, LATEST_ARTICLES_URL).to_return(:status => [code, message])
    begin
      @client.send(:get, LATEST_ARTICLES_URL)
    rescue HttpError => e
      assert_equal(code, e.http_code)
      assert_equal(message, e.http_message)
    else
      flunk 'Should have raised HttpError'
    end
  end

  [:get, :post].each do |method|
    should "raise HttpError when failed response to #{method} request" do
      stub_request(method, LATEST_ARTICLES_URL).to_return(:status => [500, "Internal Server Error"])
      assert_raise(HttpError) { @client.send(method, LATEST_ARTICLES_URL) }
    end

    should "retry connection upon connection timeout to #{method} request" do
      stub_request(method, LATEST_ARTICLES_URL).to_timeout.then.to_return(:body => RESPONSE_BODY)
      @ui.expects(:warn).with("Could not connect -- retrying in 4 seconds")
      @client.send(method, LATEST_ARTICLES_URL)
      assert_equal(RESPONSE_BODY, @client.send(method, LATEST_ARTICLES_URL))
    end

    should "retry connection a maximum of certain number of times upon connection timeout to #{method} request" do
      stub_request(method, LATEST_ARTICLES_URL).to_timeout
      io_calls = sequence("IO")
      Http::Client::MAX_RETRIES.times { @ui.expects(:warn).in_sequence(io_calls) }
      assert_raise(TimeoutError) { @client.send(method, LATEST_ARTICLES_URL) }
    end

    [
      [Errno::ECONNABORTED, 'abort'],
      [Errno::ECONNRESET,   'reset']
    ].each do |error, desc|
      should "retry connection upon connection #{desc} to #{method} request" do
        stub_request(method, LATEST_ARTICLES_URL).to_raise(error).then.to_return(:body => RESPONSE_BODY)
        @ui.expects(:warn).with("Could not connect -- retrying in 4 seconds")
        @client.send(method, LATEST_ARTICLES_URL)
        assert_equal(RESPONSE_BODY, @client.send(method, LATEST_ARTICLES_URL))
      end

      should "retry connection a maximum of certain number of times upon connection #{desc} to #{method} request" do
        stub_request(method, LATEST_ARTICLES_URL).to_raise(error)
        io_calls = sequence("IO")
        Http::Client::MAX_RETRIES.times { @ui.expects(:warn).in_sequence(io_calls) }
        assert_raise(ConnectionError) { @client.send(method, LATEST_ARTICLES_URL) }
      end
    end

    should "allow access to the #{method} request object just before sending it" do
      stub_request(method, LATEST_ARTICLES_URL)
      @client.send(method, LATEST_ARTICLES_URL) do |_, request|
        request['X-Quote'] = 'You monster.'
      end
      assert_requested(method, LATEST_ARTICLES_URL, :headers => {'X-Quote' => 'You monster.'})
    end
  end

  context "for proxy support" do
    [
      ['proxy.net',             'proxy.net', 8080],
      ['http://proxy.net',      'proxy.net', 8080],
      ['https://proxy.net',     'proxy.net', 8080],
      ['http://proxy.net:8080', 'proxy.net', 8080],
      ['http://proxy.net:8182', 'proxy.net', 8182]
    ].each do |proxy_url, expected_host, expected_port|
      should "support proxy, when its URL is #{proxy_url}" do
        proxy = Http::Client.new(:http_proxy => proxy_url)
        net_http = proxy.instance_variable_get(:@http)
        assert(net_http.proxy_class?)
        assert_equal(expected_host, net_http.instance_variable_get(:@proxy_address))
        assert_equal(expected_port, net_http.instance_variable_get(:@proxy_port))
      end
    end

    should "raise CommandLineError if given invalid port" do
      assert_raise(CommandLineError) do
        Http::Client.new(:http_proxy => 'http://proxy.net:asdf')
      end
    end
  end

  context "when using client as resource" do
    setup do
      @resource = @client.as_resource(SITE_URL)
    end

    should "send GET request with custom headers to the base URL" do
      stub_request(:get, SITE_URL)
      @resource.get(CUSTOM_HEADERS)
      assert_requested(:get, SITE_URL, :headers => CUSTOM_HEADERS)
    end

    should "send POST request with payload and custom headers to the base URL" do
      stub_request(:post, SITE_URL).with(:body => PAYLOAD, :headers => CUSTOM_HEADERS)
      @resource.post(PAYLOAD, CUSTOM_HEADERS)
      assert_requested(:post, SITE_URL, :body => PAYLOAD, :headers => CUSTOM_HEADERS)
    end

    context "when constructing new resource from the original as a sub-URL" do
      setup do
        @news_resource = @resource['news']
        @expected_news_url = "#{SITE_URL}/news"
      end

      should "send GET request with custom headers to the sub-URL" do
        stub_request(:get, @expected_news_url)
        @news_resource.get(CUSTOM_HEADERS)
        assert_requested(:get, @expected_news_url, :headers => CUSTOM_HEADERS)
      end

      should "send POST request with payload and custom headers to the sub-URL" do
        stub_request(:post, @expected_news_url).with(:body => PAYLOAD, :headers => CUSTOM_HEADERS)
        @news_resource.post(PAYLOAD, CUSTOM_HEADERS)
        assert_requested(:post, @expected_news_url, :body => PAYLOAD, :headers => CUSTOM_HEADERS)
      end

      should "further construct a new resource from the original" do
        news_resource = @news_resource['top']
        expected_url = "#{SITE_URL}/news/top"
        stub_request(:get, expected_url)
        news_resource.get(CUSTOM_HEADERS)
        assert_requested(:get, expected_url, :headers => CUSTOM_HEADERS)
      end
    end
  end

  private

  def stub_sleep
    Kernel.class_eval do
      alias_method :__original_sleep, :sleep
      define_method(:sleep) { |*args| }
    end
  end

  def restore_sleep
    Kernel.class_eval do
      remove_method :sleep
      alias_method :sleep, :__original_sleep
    end
  end
end

end
