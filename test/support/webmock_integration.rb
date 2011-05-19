# coding: utf-8

require 'webmock'

module Tweetwine::Test
  module WebMockIntegration
    include WebMock::API

    def teardown
      WebMock.reset!
    end
  end
end

WebMock.disable_net_connect!
