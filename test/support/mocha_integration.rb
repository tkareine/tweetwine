# coding: utf-8

require 'mocha'

module Tweetwine::Test
  module MochaIntegration
    include Mocha::API

    def teardown
      mocha_teardown
    end
  end
end

Mocha::Configuration.prevent :stubbing_non_existent_method
