require "json"
require "rest_client"

module Tweetwine
  class Client
    COMMANDS = %w{friends}

    def initialize(options)
      @username, @password = options[:username].to_s, options[:password].to_s
      @colorize = options[:colorize]
      @num_statuses = options[:num_statuses]
    end

    def friends
      response = RestClient.get "https://#{@username}:#{@password}@twitter.com/statuses/friends_timeline.json?count=#{@num_statuses}"
      print_statuses JSON.parse(response)
    end

    private

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
