# coding: utf-8

require 'tweetwine'
require 'webmock/test_unit'

WebMock.disable_net_connect!

module Tweetwine
  module Test
    module Helper
      extend self

      def file_mode(file)
        File.stat(file).mode & 0777
      end

      def fixture_path(filename)
        File.join(File.dirname(__FILE__), 'fixture', filename)
      end

      def fixture_file(filename)
        File.open(fixture_path(filename)) do |f|
          f.readlines.join("\n")
        end
      end

      def tmp_env(vars = {})
        originals = {}
        vars.each_pair do |key, value|
          key = key.to_s
          originals[key] = ENV[key]
          ENV[key] = value
        end
        yield
      ensure
        originals.each_pair do |key, value|
          ENV[key] = value
        end
      end

      def tmp_kcode(val)
        original = $KCODE
        $KCODE = val
        yield
      ensure
        $KCODE = original
      end
    end
  end
end
