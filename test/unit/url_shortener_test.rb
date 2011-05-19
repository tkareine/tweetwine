# coding: utf-8

require 'support/unit_test_case'

module Tweetwine::Test::Unit

class UrlShortenerTest < TestCase
  before do
    mock_http
  end

  describe "for initialization" do
    it "raises exception if service should be disabled" do
      assert_raises(RuntimeError) do
        UrlShortener.new(
          :disable          => true,
          :service_url      => "http://shorten.it/create",
          :url_param_name   => "url",
          :xpath_selector   => "//input[@id='short_url']/@value")
      end
    end

    it "raises exception if service URL is not given" do
      assert_raises(RequiredOptionError) do
        UrlShortener.new(
          :service_url      => nil,
          :url_param_name   => "url",
          :xpath_selector   => "//input[@id='short_url']/@value")
      end
    end

    it "raises exception if URL parameter name is not given" do
      assert_raises(RequiredOptionError) do
        UrlShortener.new(
          :service_url      => "http://shorten.it/create",
          :url_param_name   => nil,
          :xpath_selector   => "//input[@id='short_url']/@value")
      end
    end

    it "raises exception if XPath selector is not given" do
      assert_raises(RequiredOptionError) do
        UrlShortener.new(
          :service_url      => "http://shorten.it/create",
          :url_param_name   => "url",
          :xpath_selector   => nil)
      end
    end

    it "fallbacks to use GET method if method is not given explicitly" do
      url_shortener = UrlShortener.new(
        :service_url      => "http://shorten.it/create",
        :url_param_name   => "url",
        :xpath_selector   => "//input[@id='short_url']/@value")
      @http.expects(:get)
      url_shortener.shorten("http://www.ruby-doc.org/core/")
    end

    it "raises exception if given HTTP request method is unsupported" do
      assert_raises(CommandLineError) do
        UrlShortener.new(
          :method           => "put",
          :service_url      => "http://shorten.it/create",
          :url_param_name   => "url",
          :xpath_selector   => "//input[@id='short_url']/@value")
      end
    end
  end

  describe "when configured for HTTP GET" do
    it "uses parameters as URL query parameters, with just the URL parameter" do
      url_shortener = UrlShortener.new(
        :method           => "get",
        :service_url      => "http://shorten.it/create",
        :url_param_name   => "url",
        :xpath_selector   => "//input[@id='short_url']/@value")
      @http.expects(:get).
        with("http://shorten.it/create?url=http://www.ruby-doc.org/core/")
      url_shortener.shorten("http://www.ruby-doc.org/core/")
    end

    it "uses parameters as URL query parameters, with additional extra parameters" do
      url_shortener = UrlShortener.new(
        :method           => "get",
        :service_url      => "http://shorten.it/create",
        :url_param_name   => "url",
        :extra_params     => {
          :token => "xyz"
        },
        :xpath_selector   => "//input[@id='short_url']/@value")
      @http.expects(:get).
        with("http://shorten.it/create?token=xyz&url=http://www.ruby-doc.org/core/")
      url_shortener.shorten("http://www.ruby-doc.org/core/")
    end
  end

  describe "when configured for HTTP POST" do
    it "uses parameters as payload, with just the URL parameter" do
      url_shortener = UrlShortener.new(
        :method           => "post",
        :service_url      => "http://shorten.it/create",
        :url_param_name   => "url",
        :xpath_selector   => "//input[@id='short_url']/@value")
      @http.expects(:post).
        with("http://shorten.it/create", {:url => "http://www.ruby-doc.org/core/"})
      url_shortener.shorten("http://www.ruby-doc.org/core/")
    end

    it "uses parameters as payload, with additional extra parameters" do
      url_shortener = UrlShortener.new(
        :method           => "post",
        :service_url      => "http://shorten.it/create",
        :url_param_name   => "url",
        :extra_params     => {
          :token => "xyz"
        },
        :xpath_selector   => "//input[@id='short_url']/@value")
      @http.expects(:post).
        with("http://shorten.it/create",
          :token => "xyz",
          :url   => "http://www.ruby-doc.org/core/")
      url_shortener.shorten("http://www.ruby-doc.org/core/")
    end
  end

  describe "in erroenous network situations" do
    it "passes exceptions through" do
      url_shortener = UrlShortener.new(
        :method           => "post",
        :service_url      => "http://shorten.it/create",
        :url_param_name   => "url",
        :xpath_selector   => "//input[@id='short_url']/@value")
      @http.expects(:post).
        with("http://shorten.it/create", :url => "http://www.ruby-doc.org/core/").
        raises(HttpError.new(404, "Not Found"))
      assert_raises(HttpError) { url_shortener.shorten("http://www.ruby-doc.org/core/") }
    end
  end
end

end
