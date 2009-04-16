require "json"
require "rest_client"

class Tweetwine
  def initialize(username, password)
    @username, @password = username.to_s, password.to_s
  end

  def friends_timeline
    response = RestClient.get "http://#{@username}:#{@password}@twitter.com/statuses/friends_timeline.json"
    statuses = JSON.parse(response)
    statuses.each do |status|
      puts "#{status["user"]["name"]}: #{status["text"]}"
    end
  end
end
