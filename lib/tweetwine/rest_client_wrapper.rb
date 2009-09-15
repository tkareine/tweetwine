require "rest_client"

module Tweetwine
  class ClientError < RuntimeError; end

  class RestClientWrapper
    instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }

    def initialize(io)
      @io = io
    end

    protected

    def method_missing(name, *args, &block)
      RestClient.send(name, *args, &block)
    rescue RestClient::Exception, SocketError, SystemCallError => e
      raise ClientError, e
    end
  end
end
