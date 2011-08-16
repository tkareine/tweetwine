# coding: utf-8

module Tweetwine::Test
  module Assertions
    # Asserts whether an Enumeration-like object contains all the elements.
    # Fails unless +actual+ contains the same elements as +expected+,
    # ignoring the order of the elements.
    def assert_contains_exactly(expected, actual, msg_diff_size = nil, msg_diff_elems = nil)
      assert_equal(expected.size, actual.size, message(msg_diff_size) {
        'Expected %s to be of same size as %s' % [actual.inspect, expected.inspect]
      })
      assert(Assertions.enumerable_minus_each_element(actual, expected).empty?, message(msg_diff_elems) {
        'Expected %s to contain all the elements of %s' % [actual.inspect, expected.inspect]
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

    def self.enumerable_minus_each_element(enumerable, elements)
      remaining = enumerable.dup.to_a
      elements.each do |e|
        index = remaining.index(e)
        remaining.delete_at(index) if index
      end
      remaining
    end
  end
end
