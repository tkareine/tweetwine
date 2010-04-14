# coding: utf-8

%w{
  coulda
  matchy
  fakeweb
  open4
  stringio
  time
  timecop
}.each { |lib| require lib }

FakeWeb.clean_registry
FakeWeb.allow_net_connect = false
Timecop.freeze(Time.parse("2009-10-14 01:56:15 +0300"))

require "tweetwine"

module Tweetwine
  module ExampleHelpers
    TEST_USER = "fooman"
    TEST_PASSWD = "barpwd"
    TEST_AUTH = "#{TEST_USER}:#{TEST_PASSWD}"
    TEST_PROXY_URL = "http://proxy.net:8080"

    def launch_app(args, &blk)
      lib = File.dirname(__FILE__) << "/../lib"
      executable = File.dirname(__FILE__) << "/../bin/tweetwine"
      launch_cmd = "ruby -rubygems -I#{lib} -- #{executable} #{args}"
      Open4::popen4(launch_cmd, &blk)
    end

    def launch_cli(args, *input)
      input, output = StringIO.new(input.join("\n")), StringIO.new
      extra_opts = { :input => input, :output => output }
      CLI.launch(args, "test", nil, extra_opts)
      output.string.split("\n")
    end

    def fixture(filename)
      contents = nil
      filepath = File.dirname(__FILE__) << "/fixtures/" << filename
      File.open(filepath) do |f|
        contents = f.readlines.join("\n")
      end
      contents
    end
  end
end

include Coulda
include Tweetwine
include Tweetwine::ExampleHelpers
