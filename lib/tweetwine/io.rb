# coding: utf-8

require "strscan"
require "uri"

module Tweetwine
  class IO
    COLOR_CODES = {
      :cyan     => 36,
      :green    => 32,
      :magenta  => 35,
      :yellow   => 33
    }

    HASHTAG_REGEX = /#[\w-]+/
    USERNAME_REGEX = /^(@\w+)|\s+(@\w+)/

    def initialize(options)
      @input = options[:input] || $stdin
      @output = options[:output] || $stdout
      @colors = options[:colors] || false
    end

    def prompt(prompt)
      @output.print "#{prompt}: "
      @input.gets.strip!
    end

    def info(msg)
      @output.puts(msg)
    end

    def warn(msg)
      @output.puts "Warning: #{msg}"
    end

    def confirm(msg)
      @output.print "#{msg} [yN] "
      confirmation = @input.gets.strip
      confirmation.downcase[0, 1] == "y"
    end

    def show_status_preview(status)
      @output.puts <<-END

#{format_status(status)}

      END
    end

    def show_record(record)
      clean_record(record)
      if record[:status]
        show_record_as_user_with_status(record)
      else
        show_record_as_user(record)
      end
    end

    private

    def clean_record(record)
      record.each_pair do |key, value|
        if value.is_a? Hash
          clean_record(value)
        else
          unless value.nil?
            value = value.to_s
            record[key] = value.empty? ? nil : value
          end
        end
      end
    end

    def show_record_as_user(record)
      @output.puts <<-END
#{format_user(record[:from_user])}

      END
    end

    def show_record_as_user_with_status(record)
      @output.puts <<-END
#{format_record_header(record[:from_user], record[:to_user], record[:created_at])}
#{format_status(record[:status])}

      END
    end

    def format_user(user)
      user = colorize(:green, user) if @colors
      user
    end

    def format_status(status)
      status = Util.unescape_html(status)
      if @colors
        status = colorize_matching(:yellow, status, USERNAME_REGEX)
        status = colorize_matching(:magenta, status, HASHTAG_REGEX)
        status = colorize_matching(:cyan, status, URI.extract(status, ["http", "https"]).uniq)
      end
      status
    end

    def format_record_header(from_user, to_user, created_at)
      time_diff_value, time_diff_unit = Util.humanize_time_diff(created_at, Time.now)
      if @colors
        from_user = colorize(:green, from_user)
        to_user = colorize(:green, to_user) if to_user
      end
      if to_user
        "#{from_user}, in reply to #{to_user}, #{time_diff_value} #{time_diff_unit} ago:"
      else
        "#{from_user}, #{time_diff_value} #{time_diff_unit} ago:"
      end
    end

    def colorize_matching(color, str, pattern)
      regexp = case pattern
      when Array
        Regexp.union(pattern.map { |p| Regexp.new(Regexp.escape(p)) })
      when Regexp
        pattern
      else
        raise "Unknown kind of pattern"
      end
      Util.str_gsub_by_group(str, regexp) { |s| colorize(color, s) }
    end

    def colorize(color, str)
      colorize_str(COLOR_CODES[color.to_sym], str)
    end

    def colorize_str(color_code, str)
      "\e[#{color_code}m#{str}\e[0m"
    end
  end
end
