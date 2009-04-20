require "json"
require "rest_client"

module Tweetwine
  class Client
    COMMANDS = %w{friends user}

    def initialize(options)
      @username, password = options[:username].to_s, options[:password].to_s
      @base_url = "https://#{@username}:#{password}@twitter.com/"
      @colorize = options[:colorize]
      @num_statuses = options[:num_statuses]
    end

    def friends
      print_statuses JSON.parse(get("statuses/friends_timeline.json?count=#{@num_statuses}"))
    end

    def user(user = @username, *rest)
      print_statuses JSON.parse(get("statuses/user_timeline/#{user}.json?count=#{@num_statuses}"))
    end

    private

    def get(rest)
      RestClient.get @base_url + rest
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
