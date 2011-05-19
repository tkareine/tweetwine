# coding: utf-8

module Tweetwine::Test
  module Doubles
    def mock_config
      @config = mock('Config')
      Tweetwine::CLI.stubs(:config).returns(@config)
    end

    def mock_http
      @http = mock('Http')
      Tweetwine::CLI.stubs(:http).returns(@http)
    end

    def mock_oauth
      @oauth = mock('OAuth')
      Tweetwine::CLI.stubs(:oauth).returns(@oauth)
    end

    def mock_ui
      @ui = mock('UI')
      Tweetwine::CLI.stubs(:ui).returns(@ui)
    end

    def mock_url_shortener
      @url_shortener = mock('UrlShortener')
      Tweetwine::CLI.stubs(:url_shortener).returns(@url_shortener)
    end

    def stub_config(options = {})
      @config = options
      Tweetwine::CLI.stubs(:config).returns(@config)
    end
  end
end
