#!/usr/bin/env ruby
# coding: utf-8

gem 'perftools.rb', '~> 0.5.6'

require 'tweetwine'
require 'perftools'
require 'support/common_helpers'
require 'webmock'

WebMock.disable_net_connect!

module Driver
  extend WebMock::API
  extend Tweetwine::Test::CommonHelpers

  def self.run
    stub_http_request(:get, "https://api.twitter.com/1/statuses/home_timeline.json?count=20&page=1").to_return(:body => fixture_file('home.json'))
    yield
  ensure
    WebMock.reset!
  end
end

Driver.run do
  output_path = "/tmp/tweetwine_home_bm"

  PerfTools::CpuProfiler.start(output_path) do
    1_000.times do
      Tweetwine::CLI.start %w{home}
    end
  end

  system %{pprof.rb --gif #{output_path} > #{output_path}.gif}

  puts "Profiling output: #{output_path}"
  puts "Visualization:    #{output_path}.gif"
end
