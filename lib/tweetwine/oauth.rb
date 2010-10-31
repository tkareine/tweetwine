# coding: utf-8

require "oauth"

module Tweetwine
  class OAuth
    def initialize(options)
      require_option options, :consumer_key
      require_option options, :consumer_secret
      require_option options, :access_key
      require_option options, :access_secret
      @options = options
    end

    def consumer
      @consumer ||= ::OAuth::Consumer.new(@options[:consumer_key], @options[:consumer_secret],
        :site   => "https://api.twitter.com",
        :scheme => :header
      )
    end

    def access_token
      @access_token ||= ::OAuth::AccessToken.from_hash(consumer,
        :oauth_token        => @options[:access_key],
        :oauth_token_secret => @options[:access_secret]
      )
    end

    def request_signer
      @signer ||= lambda do |connection, request|
        request.oauth! connection, consumer, access_token
      end
    end

    private

    def require_option(options, key)
      options[key] or raise RequiredOptionError.new(key, :oauth)
    end
  end
end
