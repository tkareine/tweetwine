# coding: utf-8

require "net/http"
require "uri"

module Tweetwine
  module Http
    module Retrying
      MAX_RETRIES = 3
      RETRY_BASE_WAIT_TIMEOUT = 4

      def retrying(max_retries = MAX_RETRIES, retry_base_wait_timeout = RETRY_BASE_WAIT_TIMEOUT)
        retries = 0
        begin
          yield
        rescue ConnectionError, TimeoutError
          if retries < max_retries
            retries += 1
            timeout = retry_base_wait_timeout**retries
            CLI.ui.warn("Could not connect -- retrying in #{timeout} seconds")
            sleep timeout
            retry
          else
            raise
          end
        end
      end
    end

    class Client
      include Retrying

      def initialize(options = {})
        @http = Net::HTTP::Proxy(*parse_proxy_url(options[:http_proxy]))
      end

      def get(url, headers = nil, &block)
        retrying do
          requesting(url) do |connection, uri|
            req = Net::HTTP::Get.new(uri.request_uri, headers)
            block.call(connection, req) if block
            connection.request(req)
          end
        end
      end

      def post(url, payload = nil, headers = nil, &block)
        retrying do
          requesting(url) do |connection, uri|
            req = Net::HTTP::Post.new(uri.request_uri, headers)
            req.form_data = payload if payload
            block.call(connection, req) if block
            connection.request(req)
          end
        end
      end

      def as_resource(url)
        Resource.new(self, url)
      end

      private

      def parse_proxy_url(url)
        return [nil, nil] unless url
        url = url.sub(%r{\Ahttps?://}, '')  # remove possible scheme
        proxy_addr, proxy_port = url.split(':', 2)
        begin
          proxy_port = proxy_port ? Integer(proxy_port) : 8080
        rescue ArgumentError
          raise CommandLineError, "invalid proxy port: #{proxy_port}"
        end
        [proxy_addr, proxy_port]
      end

      def requesting(url)
        uri = URI.parse(url)
        connection = @http.new(uri.host, uri.port)
        connection.use_ssl = https_scheme?(uri)
        response = yield connection, uri
        raise HttpError, "#{response.code} #{response.message}" unless response.is_a? Net::HTTPSuccess
        response.body
      rescue Errno::ECONNABORTED, Errno::ECONNRESET => e
        raise ConnectionError, e
      rescue Timeout::Error => e
        raise TimeoutError, e
      rescue Net::HTTPError => e
        raise HttpError, e
      end

      def https_scheme?(uri)
        uri.scheme == 'https'
      end
    end

    class Resource
      def initialize(client, url)
        @client = client
        @url = url
      end

      def [](suburl)
        self.class.new(@client, "#{@url}/#{suburl}")
      end

      def get(headers = nil, &block)
        @client.get(@url, headers, &block)
      end

      def post(payload = nil, headers = nil, &block)
        @client.post(@url, payload, headers, &block)
      end
    end
  end
end
