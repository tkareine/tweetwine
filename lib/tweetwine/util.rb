# coding: utf-8

require "cgi"
require "time"
require "uri"

module Tweetwine
  module Util
    extend self

    def blank?(str)
      str.nil? || str.empty?
    end

    def humanize_time_diff(from, to)
      from = Time.parse(from.to_s) unless from.is_a? Time
      to = Time.parse(to.to_s) unless to.is_a? Time

      difference = (to - from).to_i.abs

      value, unit = case difference
      when 0..59 then [difference, "sec"]
      when 60..3599 then [(difference/60.0).round, "min"]
      when 3600..86399 then [(difference/3600.0).round, "hour"]
      else [(difference/86400.0).round, "day"]
      end

      [value, pluralize_unit(value, unit)]
    end

    def stringify_hash_keys(hash)
      recursive_copy_hash(hash) { |key, value| [key.to_s, value] }
    end

    def symbolize_hash_keys(hash)
      recursive_copy_hash(hash) { |key, value| [key.to_sym, value] }
    end

    def parse_int_gt(value, default, min, name_for_error)
      if value
        value = value.to_i
        if value >= min
          value
        else
          raise ArgumentError, "Invalid #{name_for_error} -- must be greater than or equal to #{min}"
        end
      else
        default
      end
    end

    def str_gsub_by_group(str, regexp)
      dup_str = str.dup
      str_pos, dup_pos = 0, 0
      while str_pos < str.size && (match_data = regexp.match(str[str_pos..-1]))
        matching_group_indexes = indexes_of_filled_matches(match_data)

        matching_group_indexes.each do |i|
          replacement = (yield match_data[i]).to_s
          dup_str[dup_pos + match_data.begin(i), match_data[i].size] = replacement
          replacement_delta = replacement.size - match_data[i].size
          dup_pos += replacement_delta
        end

        skip_delta = match_data.end(0)
        str_pos += skip_delta
        dup_pos += skip_delta
      end
      dup_str
    end

    def percent_encode(str)
      URI.escape(str.to_s, /[^#{URI::PATTERN::UNRESERVED}]/)
    end

    def unescape_html(str)
      CGI.unescapeHTML(str.gsub('&nbsp;', ' '))
    end

    def find_hash_path(hash, path)
      return nil if hash.nil?
      path = [path] unless path.is_a? Array
      path.inject(hash) do |result, key|
        return hash.default if key.nil? || result.nil?
        result[key]
      end
    end

    private

    def recursive_copy_hash(hash, &pair_modifier)
      hash.inject({}) do |result, pair|
        value = pair.last
        value = recursive_copy_hash(value, &pair_modifier) if value.is_a? Hash
        key, value = pair_modifier.call(pair.first, value)
        result[key] = value
        result
      end
    end

    def pluralize_unit(value, unit)
      if ["hour", "day"].include?(unit) && value > 1
        unit = unit + "s"
      end
      unit
    end

    def indexes_of_filled_matches(match_data)
      if match_data.size > 1
        (1...match_data.size).to_a.reject { |i| match_data[i].nil? }
      else
        [0]
      end
    end
  end
end
