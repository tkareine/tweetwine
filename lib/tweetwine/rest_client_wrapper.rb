require "rest_client"

module Tweetwine
  class ClientError < RuntimeError; end

  class RestClientWrapper
    instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }

    MAX_RETRIES = 3
    RETRY_BASE_WAIT_TIMEOUT = 4

    def initialize(io)
      @io = io
    end

    protected

    def method_missing(name, *args, &block)
      tries = 0
      begin
        tries += 1
        RestClient.send(name, *args, &block)
      rescue Errno::ECONNRESET => e
        if tries < MAX_RETRIES
          timeout = RETRY_BASE_WAIT_TIMEOUT**tries
          @io.warn("Could not connect -- retrying in #{timeout} seconds")
          sleep timeout
          retry
        else
          raise ClientError, e
        end
      rescue RestClient::Exception, SocketError, SystemCallError => e
        raise ClientError, e
      end
    end
  end
end
