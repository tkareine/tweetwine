# coding: utf-8

module Tweetwine
  class UI
    COLOR_CODES = {
      :cyan     => 36,
      :green    => 32,
      :magenta  => 35,
      :yellow   => 33
    }.freeze
    HASHTAG_REGEX = /#[\w-]+/
    USERNAME_REGEX = /^(@\w+)|\s+(@\w+)/
    URI_SCHEMES_TO_COLORIZE = %w{http https}

    def initialize(options = {})
      @in       = options[:in]            || $stdin
      @out      = options[:out]           || $stdout
      @err      = options[:err]           || $stderr
      @colors   = options[:colors]        || false
      @reverse  = options[:show_reverse]  || false
    end

    def info(start_msg = "\n", end_msg = " done.")
      if block_given?
        @out.print start_msg
        yield
        @out.puts end_msg
      else
        @out.puts start_msg
      end
    end

    def error(msg)
      @err.puts "ERROR: #{msg}"
    end

    def warn(msg)
      @out.puts "Warning: #{msg}"
    end

    def prompt(prompt)
      @out.print "#{prompt}: "
      @in.gets.strip!
    end

    def confirm(msg)
      @out.print "#{msg} [yN] "
      confirmation = @in.gets.strip
      confirmation.downcase[0, 1] == "y"
    end

    def show_status_preview(status)
      @out.puts <<-END

#{format_status(status)}

      END
    end

    def show_tweets(tweets)
      tweets = tweets.reverse if @reverse
      tweets.each { |t| show_tweet(t) }
    end

    def show_tweet(tweet)
      if tweet.status?
        show_regular_tweet(tweet)
      else
        show_user_info_tweet(tweet)
      end
    end

    private

    def show_user_info_tweet(tweet)
      @out.puts <<-END
#{format_user(tweet.from_user)}

      END
    end

    def show_regular_tweet(tweet)
      @out.puts <<-END
#{format_header(tweet)}
#{format_status(tweet.status)}

      END
    end

    def format_user(user)
      user = colorize(:green, user) if @colors
      user
    end

    def format_status(status)
      status = Support.unescape_html(status)
      if @colors
        status = colorize_matching(:yellow,   status, USERNAME_REGEX)
        status = colorize_matching(:magenta,  status, HASHTAG_REGEX)
        status = colorize_matching(:cyan,     status, Uri.extract(status, URI_SCHEMES_TO_COLORIZE).uniq)
      end
      status
    end

    def format_header(tweet)
      from_user = tweet.from_user
      to_user   = tweet.to_user if tweet.reply?
      rt_user   = tweet.rt_user if tweet.retweet?
      if @colors
        from_user = colorize(:green, from_user)
        to_user   = colorize(:green, to_user) if tweet.reply?
        rt_user   = colorize(:green, rt_user) if tweet.retweet?
      end
      if tweet.timestamped?
        time_diff_value, time_diff_unit = Support.humanize_time_diff(tweet.created_at, Time.now)
      end
      from_part = tweet.retweet?     ? "#{rt_user} RT #{from_user}"                  : from_user
      to_part   = tweet.reply?       ? ", in reply to #{to_user}"                    : ''
      time_part = tweet.timestamped? ? ", #{time_diff_value} #{time_diff_unit} ago"  : ''
      "#{from_part}#{to_part}#{time_part}:"
    end

    def colorize_matching(color, str, pattern)
      regexp = case pattern
      when Array
        Regexp.union(pattern.map { |p| Regexp.new(Regexp.escape(p)) })
      when Regexp
        pattern
      else
        raise "unknown kind of pattern"
      end
      Support.str_gsub_by_group(str, regexp) { |s| colorize(color, s) }
    end

    def colorize(color, str)
      colorize_str(COLOR_CODES[color.to_sym], str)
    end

    def colorize_str(color_code, str)
      "\e[#{color_code}m#{str}\e[0m"
    end
  end
end
