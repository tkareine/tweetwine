# coding: utf-8

%w{
  support/common
  support/common_helpers
  support/assertions
  support/doubles
  support/mocha_integration
  support/webmock_integration
}.each { |lib| require lib }

module Tweetwine::Test
  module Unit
    class TestCase < MiniTest::Spec
      include Tweetwine
      include MochaIntegration
      include WebMockIntegration
      include Assertions
      include Doubles
      include CommonHelpers
      extend CommonHelpers
    end
  end
end
