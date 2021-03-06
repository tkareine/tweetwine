# coding: utf-8

require 'support/unit_test_case'
require 'time'

module Tweetwine::Test::Unit

class SupportTest < TestCase
  include Support

  describe "for determining emptiness" do
    [
      [nil,     true,   "nil"],
      ["",      true,   "empty string"],
      ["foo",   false,  "nonempty string"],
      [[],      true,   "empty array"],
      [%w{a b}, false,  "nonempty array"]
    ].each do |(subject, emptiness, desc)|
      it "returns #{emptiness} for blank? with #{desc}" do
        assert_equal emptiness, blank?(subject)
      end

      it "returns #{!emptiness} for present? with #{desc}" do
        assert_equal !emptiness, present?(subject)
      end

      it "returns non-empty subject for presence, when subject is #{desc}" do
        actual = presence(subject)
        expected = present?(subject) ? subject : nil
        assert_same expected, actual
      end

      it "returns value of block for presence, when subject is #{desc}" do
        actual = presence(subject) { |s| s.size }
        expected = present?(subject) ? subject.size : nil
        assert_same expected, actual
      end

      it "allows presence to be used with || operator, when subject is #{desc}" do
        alternative = "hey"
        actual = presence(subject) || alternative
        expected = present?(subject) ? subject : alternative
        assert_same expected, actual
      end
    end
  end

  describe "for humanizing time differences" do
    it "accepts string and time arguments" do
      start = '2009-01-01 01:01:00'
      stop  = Time.parse '2009-01-01 01:03:00'
      assert_commutative([2, 'min'], [start, stop]) do |a, b|
        humanize_time_diff(a, b)
      end
    end

    it "uses second granularity for time differences smaller than a minute" do
      [
        [0,   '2009-01-01 01:00:00', '2009-01-01 01:00:00'],
        [1,   '2009-01-01 00:00:59', '2009-01-01 00:01:00'],
        [1,   '2009-01-01 01:00:00', '2009-01-01 01:00:01'],
        [59,  '2009-01-01 01:00:00', '2009-01-01 01:00:59']
      ].each do |(diff, start, stop)|
        assert_commutative([diff, 'sec'], [start, stop]) do |a, b|
          humanize_time_diff(a, b)
        end
      end
    end

    it "uses minute granularity for time differences greater than a minute but smaller than an hour" do
      [
        [1,   '2009-01-01 01:00:00', '2009-01-01 01:01:00'],
        [2,   '2009-01-01 01:01:00', '2009-01-01 01:03:29'],
        [3,   '2009-01-01 01:01:00', '2009-01-01 01:03:30'],
        [59,  '2009-01-01 01:00:00', '2009-01-01 01:59:00'],
        [59,  '2009-01-01 01:00:30', '2009-01-01 01:59:00'],
        [57,  '2009-01-01 01:01:00', '2009-01-01 01:58:00']
      ].each do |(diff, start, stop)|
        assert_commutative([diff, 'min'], [start, stop]) do |a, b|
          humanize_time_diff(a, b)
        end
      end
    end

    it "uses hour granularity for time differences greater than an hour but smaller than a day" do
      [
        [1, 'hour',   '2009-01-01 01:00', '2009-01-01 02:00'],
        [2, 'hours',  '2009-01-01 01:00', '2009-01-01 03:00'],
        [2, 'hours',  '2009-01-01 01:00', '2009-01-01 03:29'],
        [3, 'hours',  '2009-01-01 01:00', '2009-01-01 03:30']
      ].each do |(diff, unit, start, stop)|
        assert_commutative([diff, unit], [start, stop]) do |a, b|
          humanize_time_diff(a, b)
        end
      end
    end

    it "uses day granularity for time differences greater than a day" do
      [
        [1, 'day',    '2009-01-01 01:00', '2009-01-02 01:00'],
        [2, 'days',   '2009-01-01 01:00', '2009-01-03 01:00'],
        [2, 'days',   '2009-01-01 01:00', '2009-01-03 12:59'],
        [3, 'days',   '2009-01-01 01:00', '2009-01-03 13:00']
      ].each do |(diff, unit, start, stop)|
        assert_commutative([diff, unit], [start, stop]) do |a, b|
          humanize_time_diff(a, b)
        end
      end
    end
  end

  describe "for recursively copying a hash" do
    ALL_KEYS_STRINGS = {
      'alpha'   => 'A',
      'beta'    => 'B',
      'charlie' => 'C',
      'delta'   => {
        'echelon' => 'E',
        'fox'     => 'F'
      }
    }
    ALL_KEYS_SYMBOLS = {
      :alpha    => 'A',
      :beta     => 'B',
      :charlie  => 'C',
      :delta    => {
        :echelon => 'E',
        :fox     => 'F'
      }
    }

    it "stringifies hash keys" do
      given = {
        :alpha    => 'A',
        'beta'    => 'B',
        :charlie  => 'C',
        :delta    => {
          :echelon  => 'E',
          'fox'     => 'F'
        }
      }
      assert_equal ALL_KEYS_STRINGS, stringify_hash_keys(given)
    end

    it "symbolizes hash keys" do
      given = {
        'alpha'   => 'A',
        :beta     => 'B',
        'charlie' => 'C',
        'delta'   => {
          'echelon' => 'E',
          :fox      => 'F'
        }
      }
      assert_equal ALL_KEYS_SYMBOLS, symbolize_hash_keys(given)
    end

    it "has symmetric property for stringify and symbolize" do
      assert_equal ALL_KEYS_STRINGS, stringify_hash_keys(symbolize_hash_keys(ALL_KEYS_STRINGS))
      assert_equal ALL_KEYS_SYMBOLS, symbolize_hash_keys(stringify_hash_keys(ALL_KEYS_SYMBOLS))
    end
  end

  describe "for parsing integers from strings, with minimum and default values, and naming parameter" do
    it "returns an integer from its string presentation" do
      assert_equal 6, parse_int_gt("6", 8, 4, "ethical working hours per day")
    end

    it "returns default value if the string parameter is falsy" do
      assert_equal 8, parse_int_gt(nil, 8, 4, "ethical working hours per day")
      assert_equal 8, parse_int_gt(false, 8, 4, "ethical working hours per day")
    end

    it "raises an error if the parsed value is less than the minimum parameter" do
      assert_raises(ArgumentError) { parse_int_gt(3, 8, 4, "ethical working hours per day") }
      assert_raises(ArgumentError) { parse_int_gt("3", 8, 4, "ethical working hours per day") }
    end
  end

  describe "for replacing the contents of a string with a regexp that uses group syntax" do
    it "replaces the contents of the string by using a single matching group of the regexp" do
      assert_equal "hEllo", str_gsub_by_group("hello", /.+(e)/) { |s| s.upcase }
      assert_equal "hEllO", str_gsub_by_group("hello", /([aeio])/) { |s| s.upcase }
      assert_equal "h<b>e</b>ll<b>o</b>", str_gsub_by_group("hello", /([aeio])/) { |s| "<b>#{s}</b>" }
      assert_equal "hll", str_gsub_by_group("hello", /([aeio])/) { |s| "" }
      assert_equal "hell", str_gsub_by_group("hello", /.+([io])/) { |s| "" }
    end

    it "replaces the contents of the string by using multiple matching groups of the regexp" do
      assert_equal "hEllO", str_gsub_by_group("hello", /([ae]).+([io])/) { |s| s.upcase }
      assert_equal "h<b>e</b>ll<b>o</b>", str_gsub_by_group("hello", /([ae]).+([io])/) { |s| "<b>#{s}</b>" }
      assert_equal "hll", str_gsub_by_group("hello", /.+([ae]).+([io])/) { |s| "" }
      assert_equal "hll", str_gsub_by_group("hello", /([ae]).+([io])/) { |s| "" }
      assert_equal "hEllo", str_gsub_by_group("hello", /^(a)|.+(e)/) { |s| s.upcase }
    end

    it "replaces the contents of the string by using the whole regexp if there are no groups in the regexp an the regexp matches" do
      assert_equal "", str_gsub_by_group("", /el/) { |s| s.upcase }
      assert_equal "hELlo", str_gsub_by_group("hello", /el/) { |s| s.upcase }
      assert_equal "h<b>e</b>ll<b>o</b>", str_gsub_by_group("hello", /e|o/) { |s| "<b>#{s}</b>" }
    end

    it "does not change the contents of the string if the regexp does not match" do
      assert_equal "", str_gsub_by_group("", /.+([ai])/) { |s| s.upcase }
      assert_equal "hello", str_gsub_by_group("hello", /.+([ai])/) { |s| s.upcase }
      assert_equal "hello", str_gsub_by_group("hello", /he(f)/) { |s| s.upcase }
    end

    it "returns a new string as the result, leaving the original string unmodified" do
      org_str = "hello"
      new_str = str_gsub_by_group(org_str, /e/) { |s| s.upcase }
      refute_same new_str, org_str
      assert_equal "hello", org_str
      assert_equal "hEllo", new_str
    end

    it "works with UTF-8 input" do
      assert_equal "Ali<b>en</b>³,<b>Pre</b>dator", str_gsub_by_group("Alien³,Predator", /(en).+(Pre)/) { |s| "<b>#{s}</b>" }
    end
  end

  describe "for unescaping HTML" do
    [
      %w{a a},
      %w{B B},
      %w{3 3},
      %w{. period},
      %w{- dash},
      %w{_ underscore},
      %w{+ plus}
    ].each do |(char, desc)|
      it "does not affect already unescaped characters, case #{desc}" do
        assert_equal char, unescape_html(char)
      end
    end

    [
      %w{&lt;   <},
      %w{&gt;   >},
      %w{&amp;  &},
      %w{&quot; "},
      %W{&nbsp; \ }
    ].each do |(input, expected)|
      it "unescapes HTML-escaped characters, case '#{input}'" do
        assert_equal expected, unescape_html(input)
      end
    end
  end

  describe "for traversing a hash with a path expression for finding a value" do
    before do
      @inner_hash = {
        :salmon => "slick"
      }
      @inner_hash.default = "no such element in inner hash"
      @outer_hash = {
        :simple => "beautiful",
        :inner  => @inner_hash,
        :fishy  => nil
      }
      @outer_hash.default = "no such element in outer hash"
    end

    it "supports both a non-array and a single element array path for finding the value" do
      assert_equal @outer_hash[:simple], find_hash_path(@outer_hash, :simple)
      assert_equal @outer_hash[:simple], find_hash_path(@outer_hash, [:simple])
    end

    it "finds a nested value with an array path" do
      assert_equal @inner_hash[:salmon], find_hash_path(@outer_hash, [:inner, :salmon])
    end

    it "returns the default value of the hash if the value cannot be found" do
      assert_equal @outer_hash.default, find_hash_path(@outer_hash, :difficult)
      assert_equal @inner_hash.default, find_hash_path(@outer_hash, [:inner, :cucumber])
      assert_equal @outer_hash.default, find_hash_path(@outer_hash, [:fishy, :no_such])
    end

    it "returns the default value of the hash if invalid path value" do
      [
        nil,
        [:no_such, nil],
        [:simple, nil],
        [:inner, nil],
        [:inner, :salmon, nil]
      ].each do |path|
        assert_equal @outer_hash.default, find_hash_path(@outer_hash, path)
      end
    end

    it "returns nil if nil hash value" do
      assert_equal nil, find_hash_path(nil, [:salmon])
    end
  end
end

end
