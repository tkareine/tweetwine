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

    def show_statuses(statuses)
      statuses.each do |status|
        time_diff_value, time_diff_unit = Util.humanize_time_diff(status["created_at"], Time.now)
        from_user = status["user"]["screen_name"]
        from_user = colorize(:green, from_user) if @colorize
        in_reply_to = status["in_reply_to_screen_name"]
        in_reply_to = if in_reply_to && !in_reply_to.empty?
          in_reply_to = colorize(:green, in_reply_to) if @colorize
          "in reply to #{in_reply_to}, "
        else
          ""
        end
        text = status["text"]
        if @colorize
          text = colorize(:yellow, text, NICK_REGEX)
          text = colorize(:cyan, text, URL_REGEX)
        end
        @output.puts <<-END
#{from_user}, #{in_reply_to}#{time_diff_value} #{time_diff_unit} ago:
#{text}

        END
      end
    end

    private

    COLOR_CODES = {
      :cyan     => 36,
      :green    => 32,
      :magenta  => 35,
      :yellow   => 33
    }.inject({}) do |result, pair|
      result[pair.first.to_sym] = "\033[#{pair.last}m"
      result
    end

    NICK_REGEX = /@\w+/
    URL_REGEX = /(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/\S*)?/i

    def colorize(color, str, matcher = nil)
      color_code = COLOR_CODES[color.to_sym]

      unless matcher
        colorize_str(color_code, str)
      else
        str.gsub(matcher) { |s| colorize_str(color_code, s) }
      end
    end

    def colorize_str(color_code, str)
      "#{color_code}#{str}\033[0m"
    end
  end
end