# coding: utf-8

begin
  require 'json'
rescue LoadError
  raise 'Could not load JSON library; do you have one installed as a gem?'
end unless defined? JSON

gem 'oauth', '~> 0.4.4'

require 'tweetwine/version'

module Tweetwine
  class Error < StandardError
    @status_code = 42

    # Idea got from Bundler.
    def self.status_code(code = nil)
      return @status_code unless code
      @status_code = code
    end

    def status_code
      self.class.status_code
    end
  end

  class CommandLineError    < Error; status_code(13); end
  class UnknownCommandError < Error; status_code(14); end

  class RequiredOptionError < Error
    status_code(15)

    attr_reader :key, :owner

    def initialize(key, owner)
      @key, @owner = key, owner
    end

    def to_s
      "#{key} is required for #{owner}"
    end
  end

  class ConnectionError     < Error; status_code(21); end
  class TimeoutError        < Error; status_code(22); end

  class HttpError < Error
    status_code(25)

    attr_reader :http_code, :http_message

    def initialize(code, message)
      @http_code, @http_message = code.to_i, message
    end

    def to_s
      "#{http_code} #{http_message}"
    end
  end

  class TranscodeError      < Error; status_code(31); end
  class AuthorizationError  < Error; status_code(32); end

  lib_path = File.expand_path(File.dirname(__FILE__))

  require "#{lib_path}/tweetwine/basic_object"

  autoload :CharacterEncoding,  "#{lib_path}/tweetwine/character_encoding"
  autoload :CLI,                "#{lib_path}/tweetwine/cli"
  autoload :Config,             "#{lib_path}/tweetwine/config"
  autoload :Http,               "#{lib_path}/tweetwine/http"
  autoload :OAuth,              "#{lib_path}/tweetwine/oauth"
  autoload :Obfuscate,          "#{lib_path}/tweetwine/obfuscate"
  autoload :OptionParser,       "#{lib_path}/tweetwine/option_parser"
  autoload :Promise,            "#{lib_path}/tweetwine/promise"
  autoload :Support,            "#{lib_path}/tweetwine/support"
  autoload :Twitter,            "#{lib_path}/tweetwine/twitter"
  autoload :UI,                 "#{lib_path}/tweetwine/ui"
  autoload :UrlShortener,       "#{lib_path}/tweetwine/url_shortener"
end
