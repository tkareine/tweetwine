# coding: utf-8

require 'support/integration_test_case'

module Tweetwine::Test::Integration

class UseHttpProxyTest < TestCase
  HOME_URL = "https://api.twitter.com/1/statuses/home_timeline.json?count=20&page=1"

  before do
    stub_http_request(:get, HOME_URL).to_return(:body => fixture_file('home.json'))
  end

  after do
    ENV.delete 'http_proxy'
  end

  describe "enable proxy via environment variable" do
    before do
      ENV['http_proxy'] = PROXY_URL
      @output = start_cli %w{home}
    end

    it "uses the proxy to fetch my home timeline" do
      assert_use_proxy
    end
  end

  describe "enable proxy via command line option" do
    before do
      ENV.delete 'http_proxy'
      @output = start_cli %W{--http-proxy #{PROXY_URL} home}
    end

    it "uses the proxy to fetch my home timeline" do
      assert_use_proxy
    end
  end

  describe "disable proxy via command line option" do
    before do
      ENV['http_proxy'] = PROXY_URL
      @output = start_cli %w{--no-http-proxy home}
    end

    it "the application does not use the proxy to fetch my home timeline" do
      refute_use_proxy
    end
  end

  private

  def assert_use_proxy
    nh = net_http
    assert nh.proxy_class?
    nh.instance_variable_get(:@proxy_address).must_equal PROXY_HOST
    nh.instance_variable_get(:@proxy_port).must_equal PROXY_PORT
    assert_requested(:get, HOME_URL)
  end

  def refute_use_proxy
    refute net_http.proxy_class?
    assert_requested(:get, HOME_URL)
  end

  def net_http
    CLI.http.instance_variable_get(:@http)
  end
end

end
