require "time"

module Tweetwine
  module Util
    COLOR_CODES = {
      :green  => "\033[32m",
      :red    => "\033[31m"
    }

    def self.colorize(color, str, matcher = nil)
      color_code = COLOR_CODES[color.to_sym]

      unless matcher
        colorize_str(color_code, str)
      else
        str.gsub(matcher) { |s| colorize_str(color_code, s) }
      end
    end

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

    def self.parse_positive_int(str)
      value = str.to_i
      if value > 0    # nil.to_i == 0
        value
      else
        nil
      end
    end

    private

    def self.colorize_str(color_code, str)
      "#{color_code}#{str}\033[0m"
    end

    def self.pluralize_unit(value, unit)
      if ["hour", "day"].include?(unit) && value > 1
        unit = unit + "s"
      end
      unit
    end
  end
end