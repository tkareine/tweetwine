require "example_helper"

FakeWeb.register_uri(:get, "https://#{TEST_AUTH}@twitter.com/statuses/home_timeline.json?count=20&page=1", :body => fixture("home.json"))

Feature "using HTTP proxy setting" do
  in_order_to "tweet behind an HTTP proxy"
  as_a "authenticated user"
  i_want_to "tweet as before"

  Scenario "Proxy is enabled via environment variable" do
    When "application is launched" do
      ENV['http_proxy'] = TEST_PROXY_URL
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors})
    end

    Then "the latest statuses in the home view are shown via proxy" do
      RestClient.proxy.should == TEST_PROXY_URL
      @output[0].should == "pelit, 11 days ago:"
    end
  end

  Scenario "Proxy is enabled via command line option" do
    When "application is launched with --http-proxy" do
      ENV['http_proxy'] = nil
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors --http-proxy #{TEST_PROXY_URL}})
    end

    Then "the latest statuses in the home view are shown via proxy" do
      RestClient.proxy.should == TEST_PROXY_URL
      @output[0].should == "pelit, 11 days ago:"
    end
  end

  Scenario "Proxy is disabled via command line option" do
    When "application is launched with --no-http-proxy" do
      ENV['http_proxy'] = TEST_PROXY_URL
      @output = launch_cli(%W{-a #{TEST_AUTH} --no-colors --no-http-proxy})
    end

    Then "the latest statuses in the home view are shown via proxy" do
      RestClient.proxy.should == nil
      @output[0].should == "pelit, 11 days ago:"
    end
  end
end
