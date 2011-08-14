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
      include MochaIntegration
      include WebMockIntegration

      include Assertions
      include Doubles
      include CommonHelpers
      extend CommonHelpers

      # Shorten writing tests a bit by making our main namespace available in
      # the test case.
      include Tweetwine
    end
  end
end
