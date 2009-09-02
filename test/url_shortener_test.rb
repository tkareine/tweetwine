require "test_helper"

module Tweetwine

class UrlShortenerTest < Test::Unit::TestCase
  context "Upon initialization, an URL shortener" do
    should "raise exception if service URL is not given" do
      assert_raises(ArgumentError) do
        UrlShortener.new({
          :service_url      => nil,
          :url_param_name   => "url",
          :xpath_selector   => "//input[@id='short_url']/@value"
        })
      end
    end

    should "raise exception if URL parameter name is not given" do
      assert_raises(ArgumentError) do
        UrlShortener.new({
          :service_url      => "http://shorten.it/create",
          :url_param_name   => nil,
          :xpath_selector   => "//input[@id='short_url']/@value"
        })
      end
    end

    should "raise exception if XPath selector is not given" do
      assert_raises(ArgumentError) do
        UrlShortener.new({
          :service_url      => "http://shorten.it/create",
          :url_param_name   => "url",
          :xpath_selector   => nil
        })
      end
    end

    should "fallback to use GET method if not given explicitly" do
      url_shortener = UrlShortener.new({
        :service_url      => "http://shorten.it/create",
        :url_param_name   => "url",
        :xpath_selector   => "//input[@id='short_url']/@value"
      })
      assert_equal(:get, url_shortener.instance_variable_get(:@method))
    end
  end

  context "At runtime, an URL shortener" do
    context "An URL shortener configured for HTTP GET" do
      should "use parameters as URL query parameters, with just the URL parameter" do
        url_shortener = UrlShortener.new({
          :method           => "get",
          :service_url      => "http://shorten.it/create",
          :url_param_name   => "url",
          :xpath_selector   => "//input[@id='short_url']/@value"
        })
        RestClientWrapper.expects(:get) \
            .with("http://shorten.it/create?url=http://www.ruby-doc.org/core/")
        url_shortener.shorten("http://www.ruby-doc.org/core/")
      end

      should "use parameters as URL query parameters, with additional extra parameters" do
        url_shortener = UrlShortener.new({
          :method           => "get",
          :service_url      => "http://shorten.it/create",
          :url_param_name   => "url",
          :extra_params     => {
            :token => "xyz"
          },
          :xpath_selector   => "//input[@id='short_url']/@value"
        })
        RestClientWrapper.expects(:get) \
            .with("http://shorten.it/create?token=xyz&url=http://www.ruby-doc.org/core/")
        url_shortener.shorten("http://www.ruby-doc.org/core/")
      end
    end

    context "An URL shortener configured for HTTP POST" do
      should "use parameters as payload, with just the URL parameter" do
        url_shortener = UrlShortener.new({
          :method           => "post",
          :service_url      => "http://shorten.it/create",
          :url_param_name   => "url",
          :xpath_selector   => "//input[@id='short_url']/@value"
        })
        RestClientWrapper.expects(:post) \
            .with("http://shorten.it/create", {:url => "http://www.ruby-doc.org/core/"})
        url_shortener.shorten("http://www.ruby-doc.org/core/")
      end

      should "use parameters as payload,with additional extra parameters" do
        url_shortener = UrlShortener.new({
          :method           => "post",
          :service_url      => "http://shorten.it/create",
          :url_param_name   => "url",
          :extra_params     => {
            :token => "xyz"
          },
          :xpath_selector   => "//input[@id='short_url']/@value"
        })
        RestClientWrapper.expects(:post) \
            .with("http://shorten.it/create", {
              :token => "xyz",
              :url   => "http://www.ruby-doc.org/core/"
            })
        url_shortener.shorten("http://www.ruby-doc.org/core/")
      end
    end

    context "An URL shortener in erroenous situations" do
      should "raise ClientError upon connection error" do
        url_shortener = UrlShortener.new({
          :method           => "post",
          :service_url      => "http://shorten.it/create",
          :url_param_name   => "url",
          :xpath_selector   => "//input[@id='short_url']/@value"
        })
        RestClientWrapper.expects(:post) \
            .with("http://shorten.it/create", {
              :url   => "http://www.ruby-doc.org/core/"
            }) \
            .raises(ClientError, "connection error")
        assert_raises(ClientError) { url_shortener.shorten("http://www.ruby-doc.org/core/") }
      end
    end
  end
end

end
