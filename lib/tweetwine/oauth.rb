# coding: utf-8

require "cgi"
require "oauth"

module Tweetwine
  class OAuth
    SEP = ':'
    CON = Obfuscate.read(<<-END).split(SEP)
enpGfklDSjc7K0s+cklwdipiRiY6cGk8J0U5diFfZHh0JzxnfD5lPzxJcXN6
PitkPXNhYGh7M194Qyc2PHgrRkdn
    END

    def initialize(access = nil)
      @access_key, @access_secret = *if access
        Obfuscate.read(access).split(SEP)
      else
        ['', '']
      end
    end

    def authorize
      request_token = get_request_token
      CLI.ui.info "Please authorize: #{request_token.authorize_url}"
      pin = CLI.ui.prompt 'Enter PIN'
      access_token = get_access_token(request_token, pin)
      reset_access_token(access_token)
      yield(obfuscate_access_token) if block_given?
    end

    def request_signer
      @signer ||= lambda do |connection, request|
        request.oauth! connection, consumer, access_token
      end
    end

    private

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
        :oauth_token_secret => @access_secret)
    end

    def reset_access_token(access_token)
      @access_token = access_token
      @access_key = access_token.token
      @access_secret = access_token.secret
    end

    def obfuscate_access_token
      Obfuscate.write("#{@access_key}#{SEP}#{@access_secret}")
    end

    def get_request_token
      response = http_request(consumer.request_token_url) do |connection, request|
        request.oauth! connection, consumer, nil, :oauth_callback => 'oob'
      end
      ::OAuth::RequestToken.from_hash(consumer, response)
    end

    def get_access_token(request_token, pin)
      response = http_request(consumer.access_token_url) do |connection, request|
        request.oauth! connection, consumer, request_token, :oauth_verifier => pin
      end
      ::OAuth::AccessToken.from_hash(consumer, response)
    end

    def http_request(url, &block)
      method = consumer.http_method
      response = CLI.http.send(method, url) do |connection, request|
        request['Content-Length'] = '0'
        block.call(connection, request)
      end
      parse_url_encoding(response)
    rescue HttpError => e
      # Do not raise HttpError with 401 response since that is expected this
      # module to deal with.
      if (400...500).include? e.http_code
        raise AuthorizationError, "Unauthorized to #{method.to_s.upcase} #{url} for OAuth: #{e}"
      else
        raise
      end
    end

    def parse_url_encoding(response)
      CGI.parse(response).inject({}) do |hash, (key, value)|
        key = key.strip
        hash[key] = hash[key.to_sym] = value.first
        hash
      end
    end
  end
end
