require "json"
require "rest_client"

module Tweetwine
  class ClientError < RuntimeError; end

  class Client
    COMMANDS = %w{friends user update}

    MAX_NUM_STATUSES = 20
    MAX_STATUS_LENGTH = 140

    def initialize(options)
      @username, password = options[:username].to_s, options[:password].to_s
      @base_url = "https://#{@username}:#{password}@twitter.com/"
      @colorize = options[:colorize] || false
      @num_statuses = options[:num_statuses] || MAX_NUM_STATUSES
      @io = IO.new(options)
    end

    def friends
      @io.show_statuses JSON.parse(get("statuses/friends_timeline.json?count=#{@num_statuses}"))
    end

    def user(user = @username)
      @io.show_statuses JSON.parse(get("statuses/user_timeline/#{user}.json?count=#{@num_statuses}"))
    end

    def update(new_status = nil)
      new_status = @io.prompt("Status update") unless new_status
      if new_status.length > MAX_STATUS_LENGTH
        new_status = new_status[0...MAX_STATUS_LENGTH]
        @io.warn("Update will be truncated: #{new_status}")
      end
      if @io.confirm("Really send?")
        status = JSON.parse(post("statuses/update.json", {:status => new_status}))
        @io.info "Sent status update.\n\n"
        @io.show_statuses([status])
      else
        @io.info "Cancelled."
      end
    end

    private

    def get(rest_url)
      rest_client_action(:get, @base_url + rest_url)
    end

    def post(rest_url, body)
      rest_client_action(:post, @base_url + rest_url, body)
    end

    def rest_client_action(action, *args)
      RestClient.send(action, *args)
    rescue RestClient::Exception => e
      raise ClientError, e.message
    end
  end
end
