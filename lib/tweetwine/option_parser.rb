# coding: utf-8

require "optparse"

module Tweetwine
  class OptionParser
    def initialize(&blk)
      @options = {}
      @parser = ::OptionParser.new do |parser|
        blk.call(parser, @options)
      end
    end

    def parse(args = ARGV)
      @parser.order! args
      result = @options.dup
      @options.clear
      result
    rescue ::OptionParser::ParseError => e
      raise CommandLineError, e.message
    end

    def help
      @parser.summarize.join.chomp
    end
  end
end
