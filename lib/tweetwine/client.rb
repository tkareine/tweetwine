require "json"
require "rest_client"

module Tweetwine
  class Client
    COMMANDS = %w{friends}

    def initialize(username, password)
      @username, @password = username.to_s, password.to_s
    end

    def friends
      response = RestClient.get "https://#{@username}:#{@password}@twitter.com/statuses/friends_timeline.json"
      statuses = JSON.parse(response)
      statuses.each do |status|
        time_diff_value, time_diff_unit = Util.humanize_time_diff(Time.now, status["created_at"])
        puts <<-END
#{status["user"]["screen_name"]}, #{time_diff_value} #{time_diff_unit} ago:
#{status["text"]}
      
        END
      end
    end
  end
end
