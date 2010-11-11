# coding: utf-8

%w{
  coulda
  matchy
  open4
  stringio
  tempfile
  time
  timecop
  webmock/test_unit
}.each { |lib| require lib }

Timecop.freeze(Time.parse("2009-10-14 01:56:15 +0300"))

require "tweetwine"
require "test_helper"

module Tweetwine
  module Example
    module Helper
      include WebMock::API
      include Test::Helper

      CONFIG_FILE = File.expand_path('../fixture/config.yaml', __FILE__)
      PROXY_HOST = "proxy.net"
      PROXY_PORT = 8123
      PROXY_URL = "http://#{PROXY_HOST}:#{PROXY_PORT}"
      USER = "fooman"

      def start_app(args, &blk)
        lib = File.dirname(__FILE__) << "/../lib"
        executable = File.dirname(__FILE__) << "/../bin/tweetwine"
        launch_cmd = "env USER='#{USER}' ruby -rubygems -I#{lib} -- #{executable} -f #{CONFIG_FILE} #{args.join(' ')}"
        Open4::popen4(launch_cmd, &blk)
      end

      def start_cli(args, input = [], options = {:config_file => CONFIG_FILE})
        input, output = StringIO.new(input.join("\n")), StringIO.new
        options.merge!({ :in => input, :out => output })
        CLI.start(args, options)
        output.string.split("\n")
      end

      def fixture(filename)
        filepath = File.expand_path("../fixture/#{filename}", __FILE__)
        File.open(filepath) do |f|
          f.readlines.join("\n")
        end
      end

      def in_temp_dir
        Dir.mktmpdir do |tmp_dir|
          Dir.chdir(tmp_dir) do |dir|
            yield dir
          end
        end
      end

      def read_shorten_config
        Util.symbolize_hash_keys(YAML.load_file(CONFIG_FILE))[:shorten_urls]
      end
    end
  end
end

include Coulda
include Tweetwine
include Tweetwine::Example::Helper
