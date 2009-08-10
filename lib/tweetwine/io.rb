require "uri"

module Tweetwine
  class IO
    COLOR_CODES = {
      :cyan     => 36,
      :green    => 32,
      :magenta  => 35,
      :yellow   => 33
    }

    NICK_REGEX = /@\w+/

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

    def show(record)
      if record[:status]
        show_as_status(record)
      else
        show_as_user(record)
      end
    end

    def show_as_status(record)
      time_diff_value, time_diff_unit = Util.humanize_time_diff(record[:status][:created_at], Time.now)
      from_user = record[:user]
      colorize!(:green, from_user) if @colorize
      in_reply_to = record[:status][:in_reply_to]
      in_reply_to = if in_reply_to && !in_reply_to.empty?
        colorize!(:green, in_reply_to) if @colorize
        "in reply to #{in_reply_to}, "
      else
        ""
      end
      status = record[:status][:text]
      if @colorize
        colorize_all!(:yellow, status, NICK_REGEX)
        URI.extract(status, ["http", "https"]).each do |url|
          colorize_first!(:cyan, status, url)
        end
      end
      @output.puts <<-END
#{from_user}, #{in_reply_to}#{time_diff_value} #{time_diff_unit} ago:
#{status}

      END
    end

    def show_as_user(record)
      user = record[:user]
      colorize!(:green, user) if @colorize
      @output.puts <<-END
#{user}

      END
    end

    private

    def colorize_all!(color, str, pattern)
      str.gsub!(pattern) { |s| colorize_str(COLOR_CODES[color.to_sym], s) }
    end

    def colorize_first!(color, str, pattern)
      str.sub!(pattern) { |s| colorize_str(COLOR_CODES[color.to_sym], s) }
    end

    def colorize!(color, str)
      str.replace colorize_str(COLOR_CODES[color.to_sym], str)
    end

    def colorize_str(color_code, str)
      "\033[#{color_code}m#{str}\033[0m"
    end
  end
end