require "time"

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

    private

    def self.pluralize_unit(value, unit)
      if ["hour", "day"].include?(unit) && value > 1
        unit = unit + "s"
      end
      unit
    end
  end
end
