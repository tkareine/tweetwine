module Tweetwine
  class IO
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

    def print_statuses(statuses)
      statuses.each do |status|
        time_diff_value, time_diff_unit = Util.humanize_time_diff(Time.now, status["created_at"])
        from_user = status["user"]["screen_name"]
        from_user = colorize(:green, from_user) if @colorize
        text = status["text"]
        text = colorize(:red, text, /@\w+/) if @colorize
        @output.puts <<-END
#{from_user}, #{time_diff_value} #{time_diff_unit} ago:
#{text}

        END
      end
    end

    private

    COLOR_CODES = {
      :green    => "\033[32m",
      :red      => "\033[31m",
      :neutral  => "\033[0m"
    }

    def colorize(color, str, matcher = nil)
      color_code = COLOR_CODES[color.to_sym]

      unless matcher
        colorize_str(color_code, str)
      else
        str.gsub(matcher) { |s| colorize_str(color_code, s) }
      end
    end

    def colorize_str(color_code, str)
      "#{color_code}#{str}#{COLOR_CODES[:neutral]}"
    end
  end
end