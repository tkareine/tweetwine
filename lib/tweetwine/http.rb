# coding: utf-8

require "rest_client"

module Tweetwine
  module Http
    def self.proxy=(url)
      RestClient.proxy = url
    end

    class Base
      MAX_RETRIES = 3
      RETRY_BASE_WAIT_TIMEOUT = 4

      def self.use_retries_with(*methods)
        module_eval do
          methods.each do |method_name|
            non_retrying_method_name = :"__original_#{method_name}"
            alias_method non_retrying_method_name, method_name
            define_method(method_name) do |*args|
              do_with_retries { send(non_retrying_method_name, *args).to_s }
            end
          end
        end
      end

      private

      def do_with_retries
        retries = 0
        begin
          yield
        rescue Errno::ECONNRESET, RestClient::RequestTimeout => e
          if retries < MAX_RETRIES
            retries += 1
            timeout = RETRY_BASE_WAIT_TIMEOUT**retries
            CLI.ui.warn("Could not connect -- retrying in #{timeout} seconds")
            sleep timeout
            retry
          else
            raise HttpError, e
          end
        rescue RestClient::Exception, SocketError, SystemCallError => e
          raise HttpError, e
        end
      end
    end

    class Client < Base
      def initialize(options = {})
        Http.proxy = options[:http_proxy] if options[:http_proxy]
      end

      def get(*args)
        RestClient.get(*args)
      end

      def post(*args)
        RestClient.post(*args)
      end

      def as_resource(url, options = {})
        Resource.new(RestClient::Resource.new(url, options))
      end

      use_retries_with :get, :post
    end

    class Resource < Base
      def initialize(wrapped_resource)
        @wrapped = wrapped_resource
      end

      def [](suburl)
        new(@wrapped[suburl])
      end

      def get(*args)
        @wrapped.get(*args)
      end

      def post(*args)
        @wrapped.post(*args)
      end

      use_retries_with :get, :post
    end
  end
end
