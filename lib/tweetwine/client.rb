require "json"
require "rest_client"

module Tweetwine
  class Client
    COMMANDS = %w{friends}

    def initialize(options)
      @username, @password = options[:username].to_s, options[:password].to_s
      @colorize = options[:colorize]
    end

    def friends
      response = RestClient.get "https://#{@username}:#{@password}@twitter.com/statuses/friends_timeline.json"
      print_statuses JSON.parse(response)
    end

    private

    def print_statuses(statuses)
      statuses.each do |status|
        time_diff_value, time_diff_unit = Util.humanize_time_diff(Time.now, status["created_at"])
        puts <<-END
#{Util.colorize(status["user"]["screen_name"], :red)}, #{time_diff_value} #{time_diff_unit} ago:
#{status["text"]}

        END
      end
    end
  end
end
