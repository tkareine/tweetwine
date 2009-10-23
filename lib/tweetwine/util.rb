require "time"
require "uri"

module Tweetwine
  module Util
    def self.humanize_time_diff(from, to)
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

    def self.symbolize_hash_keys(hash)
      hash.inject({}) do |result, pair|
        value = pair.last
        value = symbolize_hash_keys(value) if value.is_a? Hash
        result[pair.first.to_sym] = value
        result
      end
    end

    def self.parse_int_gt(value, default, min, name_for_error)
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

    def self.str_gsub_by_group(str, regexp)
      dup_str = str.dup
      index, dup_index = 0, 0
      while index < str.size && (match_data = regexp.match(str[index..-1]))
        matching_group_indexes = indexes_of_filled_matches(match_data)

        matching_group_indexes.each do |i|
          replacement = (yield match_data[i]).to_s
          dup_str[dup_index + match_data.begin(i), match_data[i].size] = replacement
          replacement_delta = replacement.size - match_data[i].size
          dup_index += replacement_delta
        end
        skip_delta = match_data.end(0)
        index += skip_delta
        dup_index += skip_delta
      end
      dup_str
    end

    def self.percent_encode(str)
      URI.escape(str.to_s, /[^#{URI::PATTERN::UNRESERVED}]/)
    end

    def self.find_hash_path(hash, path)
      return nil if hash.nil?
      path = [path] if !path.is_a? Array
      path.inject(hash) do |result, key|
        return hash.default if key.nil? || result.nil?
        result[key]
      end
    end

    private

    def self.pluralize_unit(value, unit)
      if ["hour", "day"].include?(unit) && value > 1
        unit = unit + "s"
      end
      unit
    end

    def self.indexes_of_filled_matches(match_data)
      if match_data.size > 1
        (1...match_data.size).to_a.reject { |i| match_data[i].nil? }
      else
        [0]
      end
    end
  end
end
