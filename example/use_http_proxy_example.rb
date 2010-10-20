# coding: utf-8

require "example_helper"

Feature "using HTTP proxy" do
  in_order_to "tweet behind an HTTP proxy"
  as_a "authenticated user"
  i_want_to "tweet as before"

  def setup
    super
    stub_http_request(:get, "https://api.twitter.com/1/statuses/home_timeline.json?count=20&page=1").to_return(:body => fixture("home.json"))
  end

  Scenario "enabling proxy via environment variable" do
    When "I have defined proxy in environment variable before starting the application with 'home' command" do
      ENV['http_proxy'] = PROXY_URL
      @output = start_cli %w{home}
    end

    Then "the application uses the proxy to fetch my home timeline" do
      RestClient.proxy.should == PROXY_URL
      @output[0].should == "pelit, 11 days ago:"
    end
  end

  Scenario "enabling proxy via command line option" do
    When "I start the application with --http-proxy option and 'home' command" do
      ENV['http_proxy'] = nil
      @output = start_cli %W{--http-proxy #{PROXY_URL} home}
    end

    Then "the application uses the proxy to fetch my home timeline" do
      RestClient.proxy.should == PROXY_URL
      @output[0].should == "pelit, 11 days ago:"
    end
  end

  Scenario "disabling proxy via command line option" do
    When "I start the application with --http-proxy option and 'home' command" do
      ENV['http_proxy'] = PROXY_URL
      @output = start_cli %w{--no-http-proxy home}
    end

    Then "the application does not use the proxy to fetch my home timeline" do
      RestClient.proxy.should == nil
      @output[0].should == "pelit, 11 days ago:"
    end
  end
end
