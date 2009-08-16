require File.dirname(__FILE__) << "/test_helper"

module Tweetwine

class UrlShortenerTest < Test::Unit::TestCase
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

    should "use parameters as payload, with just the URL parameter" do
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
end

end
