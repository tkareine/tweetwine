# coding: utf-8

begin
  require 'json'
rescue LoadError
  raise 'Could not load JSON library; do you have one installed as a gem?'
end unless defined? JSON

gem 'oauth', '~> 0.4.4'

require 'tweetwine/version'

module Tweetwine
  lib_path = File.expand_path(File.dirname(__FILE__))

  require "#{lib_path}/tweetwine/exceptions"
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
  autoload :Tweet,              "#{lib_path}/tweetwine/tweet"
  autoload :Twitter,            "#{lib_path}/tweetwine/twitter"
  autoload :UI,                 "#{lib_path}/tweetwine/ui"
  autoload :Uri,                "#{lib_path}/tweetwine/uri"
  autoload :UrlShortener,       "#{lib_path}/tweetwine/url_shortener"
end
