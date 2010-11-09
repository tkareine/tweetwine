# coding: utf-8

require "oauth"

module Tweetwine
  class OAuth
    SEP = ':'
    CON = Obfuscate.read(<<-END).split(SEP)
enpGfklDSjc7K0s+cklwdipiRiY6cGk8J0U5diFfZHh0JzxnfD5lPzxJcXN6
PitkPXNhYGh7M194Qyc2PHgrRkdn
    END

    def initialize(access)
      @access_key, @access_secret = *if access
        Obfuscate.read(access).split(SEP)
      else
        ['', '']
      end
    end

    def authorize
      request_token = consumer.get_request_token(:oauth_callback => 'oob')
      CLI.ui.info "Please authorize: #{request_token.authorize_url}"
      pin = CLI.ui.prompt 'Enter PIN'
      access_token = request_token.get_access_token(:oauth_verifier => pin)
      @access_token = nil   # reset
      @access_key = access_token.token
      @access_secret = access_token.secret
      access_obfuscated = Obfuscate.write("#{@access_key}#{SEP}#{@access_secret}")
      yield(access_obfuscated) if block_given?
    end

    def consumer
      @consumer ||= ::OAuth::Consumer.new(CON[0], CON[1],
        :site               => 'https://api.twitter.com',
        :scheme             => :header,
        :http_method        => :post,
        :request_token_path => '/oauth/request_token',
        :authorize_path     => '/oauth/authorize',
        :access_token_path  => '/oauth/access_token')
    end

    def access_token
      @access_token ||= ::OAuth::AccessToken.from_hash(consumer,
        :oauth_token        => @access_key,
        :oauth_token_secret => @access_secret
      )
    end

    def request_signer
      @signer ||= lambda do |connection, request|
        request.oauth! connection, consumer, access_token
      end
    end
  end
end
