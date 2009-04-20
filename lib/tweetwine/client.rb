require "json"
require "rest_client"

module Tweetwine
  class Client
    COMMANDS = %w{friends user msg}

    MAX_NUM_STATUSES = 20
    MAX_STATUS_LENGTH = 140

    def initialize(options)
      @username, password = options[:username].to_s, options[:password].to_s
      @base_url = "https://#{@username}:#{password}@twitter.com/"
      @colorize = options[:colorize]
      @num_statuses = options[:num_statuses]
    end

    def friends
      print_statuses JSON.parse(get("statuses/friends_timeline.json?count=#{@num_statuses}"))
    end

    def user(user = @username)
      print_statuses JSON.parse(get("statuses/user_timeline/#{user}.json?count=#{@num_statuses}"))
    end

    def msg(status = nil)
      unless status
        printf "New status message: "
        status = $stdin.gets
      end
      if confirm_user_action("Really send?")
        msg = status[0...MAX_STATUS_LENGTH]
        body = {:status => msg }
        status = JSON.parse(post("statuses/update.json", body))
        puts "Sent new status message.\n\n"
        print_statuses([status])
      else
        puts "Cancelled."
      end
    end

    private

    def get(rest_uri)
      RestClient.get @base_url + rest_uri
    end

    def post(rest_url, body)
      RestClient.post @base_url + rest_url, body
    end

    def confirm_user_action(msg)
      printf "#{msg} [yn] "
      confirmation = $stdin.gets.strip
      confirmation =~ /y/i
    end

    def print_statuses(statuses)
      statuses.each do |status|
        time_diff_value, time_diff_unit = Util.humanize_time_diff(Time.now, status["created_at"])
        from_user = status["user"]["screen_name"]
        from_user = Util.colorize(:green, from_user) if @colorize
        text = status["text"]
        text = Util.colorize(:red, text, /@\w+/) if @colorize
        puts <<-END
#{from_user}, #{time_diff_value} #{time_diff_unit} ago:
#{text}

        END
      end
    end
  end
end
