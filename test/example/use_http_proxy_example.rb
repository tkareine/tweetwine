# coding: utf-8

require 'example/helper'

Feature "using HTTP proxy" do
  as_a "authenticated user"
  i_want_to "use HTTP proxy"
  in_order_to "tweet behind a firewall"

  HOME_URL = "https://api.twitter.com/1/statuses/home_timeline.json?count=20&page=1"

  def setup
    super
    stub_http_request(:get, HOME_URL).to_return(:body => fixture_file('home.json'))
  end

  Scenario "enable proxy via environment variable" do
    When "I have proxy in envar, and start the application with 'home' command" do
      ENV['http_proxy'] = PROXY_URL
      @output = start_cli %w{home}
    end

    Then "the application uses the proxy to fetch my home timeline" do
      should_use_proxy
    end
  end

  Scenario "enable proxy via command line option" do
    When "I start the application with --http-proxy option and 'home' command" do
      ENV['http_proxy'] = nil
      @output = start_cli %W{--http-proxy #{PROXY_URL} home}
    end

    Then "the application uses the proxy to fetch my home timeline" do
      should_use_proxy
    end
  end

  Scenario "disable proxy via command line option" do
    When "I have proxy in envar, and start the application with --no-http-proxy option and 'home' command" do
      ENV['http_proxy'] = PROXY_URL
      @output = start_cli %w{--no-http-proxy home}
    end

    Then "the application does not use the proxy to fetch my home timeline" do
      should_not_use_proxy
    end
  end

  private

  def should_use_proxy
    nh = net_http
    nh.proxy_class?.should == true
    nh.instance_variable_get(:@proxy_address).should == PROXY_HOST
    nh.instance_variable_get(:@proxy_port).should == PROXY_PORT
    assert_requested(:get, HOME_URL)
  end

  def should_not_use_proxy
    net_http.proxy_class?.should == false
    assert_requested(:get, HOME_URL)
  end

  def net_http
    CLI.http.instance_variable_get(:@http)
  end
end
