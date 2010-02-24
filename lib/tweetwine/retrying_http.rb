require "rest_client"

module Tweetwine
  class HttpError < RuntimeError; end

  module RetryingHttp
    def self.proxy=(url)
      RestClient.proxy = url
    end

    class Base
      MAX_RETRIES = 3
      RETRY_BASE_WAIT_TIMEOUT = 4

      def self.use_retries_with(*methods)
        methods.each do |method_name|
          module_eval do
            non_retrying_method_name = "original_#{method_name}".to_sym
            alias_method non_retrying_method_name, method_name
            define_method(method_name) do |*args|
              do_with_retries { send(non_retrying_method_name, *args) }
            end
          end
        end
      end

      private

      def do_with_retries
        tries = 0
        begin
          tries += 1
          yield
        rescue Errno::ECONNRESET, RestClient::RequestTimeout => e
          if tries < MAX_RETRIES
            timeout = RETRY_BASE_WAIT_TIMEOUT**tries
            @io.warn("Could not connect -- retrying in #{timeout} seconds") if @io
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
      attr_accessor :io

      def initialize(io)
        @io = io
      end

      def get(*args)
        RestClient.get(*args)
      end

      def post(*args)
        RestClient.post(*args)
      end

      def as_resource(url, options = {})
        resource = Resource.new(RestClient::Resource.new(url, options))
        resource.io = @io
        resource
      end

      use_retries_with :get, :post
    end

    class Resource < Base
      attr_accessor :io

      def initialize(wrapped_resource)
        @wrapped = wrapped_resource
      end

      def [](suburl)
        instance = self.class.new(@wrapped[suburl])
        instance.io = @io
        instance
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
