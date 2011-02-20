# coding: utf-8

require 'uri'

module Tweetwine
  module Uri
    UNSAFE_CHARS_REGEXP = /[^#{URI::PATTERN::UNRESERVED}]/

    class << self
      def parser
        if ::URI.const_defined? :Parser
          @parser ||= ::URI::Parser.new
        else
          ::URI
        end
      end

      def extract(*args)
        parser.extract(*args)
      end

      def parse(*args)
        parser.parse(*args)
      end

      def percent_encode(str)
        parser.escape(str.to_s, UNSAFE_CHARS_REGEXP)
      end
    end
  end
end
