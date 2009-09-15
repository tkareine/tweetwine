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
    USERNAME_REGEX = /@\w+/

    def initialize(options)
      @input = options[:input] || $stdin
      @output = options[:output] || $stdout
      @colorize = options[:colorize] || false
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
      confirmation.downcase[0,1] == "y"
    end

    def show_status_preview(status)
      @output.puts <<-END

#{format_status(status)}

      END
    end

    def show_record(record)
      if record[:status]
        show_record_as_user_with_status(record)
      else
        show_record_as_user(record)
      end
    end

    private

    def show_record_as_user(record)
      @output.puts <<-END
#{format_user(record[:user])}

      END
    end

    def show_record_as_user_with_status(record)
      @output.puts <<-END
#{format_record_header(record)}
#{format_status(record[:status][:text])}

      END
    end

    def format_user(user)
      user = user.dup
      colorize!(:green, user) if @colorize
      user
    end

    def format_status(status)
      status = status.dup
      if @colorize
        colorize_all!(:yellow, status, USERNAME_REGEX)
        colorize_all!(:magenta, status, HASHTAG_REGEX)
        URI.extract(status, ["http", "https"]).uniq.each do |url|
          colorize_all!(:cyan, status, url)
        end
      end
      status
    end

    def format_record_header(record)
      time_diff_value, time_diff_unit = Util.humanize_time_diff(record[:status][:created_at], Time.now)
      from_user = record[:user].dup
      colorize!(:green, from_user) if @colorize
      in_reply_to = record[:status][:in_reply_to]
      in_reply_to = if in_reply_to && !in_reply_to.empty?
        in_reply_to = colorize!(:green, in_reply_to.dup) if @colorize
        "in reply to #{in_reply_to}, "
      else
        ""
      end
      "#{from_user}, #{in_reply_to}#{time_diff_value} #{time_diff_unit} ago:"
    end

    def colorize_all!(color, str, pattern)
      str.gsub!(pattern) { |s| colorize_str(COLOR_CODES[color.to_sym], s) }
    end

    def colorize!(color, str)
      str.replace colorize_str(COLOR_CODES[color.to_sym], str)
    end

    def colorize_str(color_code, str)
      "\033[#{color_code}m#{str}\033[0m"
    end
  end
end
