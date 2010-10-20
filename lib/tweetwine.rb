# coding: utf-8

module Tweetwine
  VERSION = "0.2.12".freeze

  class Error < StandardError
    @code = 42

    # Idea got from Bundler.
    def self.status_code(code = nil)
      return @code unless code
      @code = code
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
  class HttpError           < Error; status_code(22); end

  class TranscodeError      < Error; status_code(31); end

  require "tweetwine/basic_object"

  autoload :CharacterEncoding,  "tweetwine/character_encoding"
  autoload :CLI,                "tweetwine/cli"
  autoload :Config,             "tweetwine/config"
  autoload :Http,               "tweetwine/http"
  autoload :OAuth,              "tweetwine/oauth"
  autoload :OptionParser,       "tweetwine/option_parser"
  autoload :Promise,            "tweetwine/promise"
  autoload :Twitter,            "tweetwine/twitter"
  autoload :UI,                 "tweetwine/ui"
  autoload :UrlShortener,       "tweetwine/url_shortener"
  autoload :Util,               "tweetwine/util"
end
