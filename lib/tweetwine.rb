# coding: utf-8

begin
  require 'json'
rescue LoadError
  raise 'Could not load JSON library; do you have one installed as a gem?'
end unless defined? JSON

require 'tweetwine/version'

module Tweetwine
  require 'tweetwine/exceptions'
  require 'tweetwine/basic_object'

  autoload :CharacterEncoding,  'tweetwine/character_encoding'
  autoload :CLI,                'tweetwine/cli'
  autoload :Config,             'tweetwine/config'
  autoload :Http,               'tweetwine/http'
  autoload :OAuth,              'tweetwine/oauth'
  autoload :Obfuscate,          'tweetwine/obfuscate'
  autoload :OptionParser,       'tweetwine/option_parser'
  autoload :Promise,            'tweetwine/promise'
  autoload :Support,            'tweetwine/support'
  autoload :Tweet,              'tweetwine/tweet'
  autoload :Twitter,            'tweetwine/twitter'
  autoload :UI,                 'tweetwine/ui'
  autoload :Uri,                'tweetwine/uri'
  autoload :UrlShortener,       'tweetwine/url_shortener'
end
