# coding: utf-8

require "test_helper"

require "contest"
require "mocha"

Mocha::Configuration.prevent(:stubbing_non_existent_method)

module Tweetwine::Test
  module Assertions
    # Asserts whether an Enumeration like object contains all the elements.
    # Fails unless +actual+ contains the same elements as +expected+, ignoring
    # the order of the elements.
    #
    # This method sorts +expected+ and +actual+ in order to compare them. By
    # default, sorting is done by calling #sort for each of them. If this
    # method is called with a block, it is passed to the #sort calls.
    def assert_contains_exactly(expected, actual, msg = nil, &sorter)
      expected = block_given? ? expected.sort(&sorter) : expected.sort
      actual   = block_given? ? actual.sort(&sorter)   : actual.sort
      assert_equal(expected, actual, message(msg) {
        'After sorting, expected %s, not %s' % [expected.inspect, actual.inspect]
      })
    end

    # Fails unless +str+ is a full match to +regex+.
    def assert_full_match(regex, str, msg = nil)
      match_data = regex.match(str)
      assert(str == match_data.to_s, message(msg) {
        'Expected %s to be a full match to %s' % [str, regex.inspect]
      })
    end

    # Fails if +str+ is a full match to +regex+.
    def assert_no_full_match(regex, str, msg = nil)
      match_data = regex.match(str)
      assert(str != match_data.to_s, message(msg) {
        'Expected %s not to be a full match to %s' % [str, regex.inspect]
      })
    end

    # Fails unless +fun.call(*args)+ is equal to +expected+ and
    # +fun.call(*args)+ is equal to +fun.call(*args.reverse)+.
    def assert_commutative(expected, args, msg_not_expected = nil, msg_not_commutative = nil, &fun)
      left_args = args
      left_actual = fun.call(left_args)
      assert_equal(expected, left_actual, message(msg_not_expected) {
        'Expected %s, not %s' % [expected.inspect, left_actual.inspect]
      })
      right_args = args.reverse
      right_actual = fun.call(*right_args)
      assert_equal(left_actual, right_actual, message(msg_not_commutative) {
        'Expected fun%s => %s to be commutative with fun%s => %s' %
          [left_args.inspect, left_actual.inspect, right_args.inspect, right_actual.inspect]
      })
    end

    private

    def message(given, &default)
      given.nil? ? default.call : given
    end
  end

  module Doubles
    def mock_config
      @config = mock('Config')
      Tweetwine::CLI.stubs(:config).returns(@config)
    end

    def mock_http
      @http = mock('Http')
      Tweetwine::CLI.stubs(:http).returns(@http)
    end

    def mock_oauth
      @oauth = mock('OAuth')
      Tweetwine::CLI.stubs(:oauth).returns(@oauth)
    end

    def mock_ui
      @ui = mock('UI')
      Tweetwine::CLI.stubs(:ui).returns(@ui)
    end

    def mock_url_shortener
      @url_shortener = mock('UrlShortener')
      Tweetwine::CLI.stubs(:url_shortener).returns(@url_shortener)
    end

    def stub_config(options = {})
      @config = options
      Tweetwine::CLI.stubs(:config).returns(@config)
    end
  end

  class UnitTestCase < ::Test::Unit::TestCase
    include WebMock::API
    include Tweetwine
    include Helper
    include Assertions
    include Doubles
  end
end
