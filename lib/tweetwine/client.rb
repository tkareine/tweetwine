require "json"
require "rest_client"

module Tweetwine
  class ClientError < RuntimeError; end

  class Client
    attr_reader :num_statuses

    COMMANDS = [:home, :mentions, :user, :update]

    DEFAULT_NUM_STATUSES = 20
    MAX_NUM_STATUSES = 200
    MAX_STATUS_LENGTH = 140

    def initialize(options)
      @username = options[:username].to_s
      raise ArgumentError, "No authentication data given" if @username.empty?
      @base_url = "https://#{@username}:#{options[:password]}@twitter.com/"
      @colorize = options[:colorize] || false
      @num_statuses = if options[:num_statuses]
        if (1..MAX_NUM_STATUSES).include? options[:num_statuses]
          options[:num_statuses]
        else
          raise ArgumentError, "Invalid number of statuses to show -- must be between 1..#{MAX_NUM_STATUSES}"
        end
      else
        DEFAULT_NUM_STATUSES
      end
      @io = IO.new(options)
    end

    def home
      get_and_show "statuses/friends_timeline.json?count=#{@num_statuses}"
    end

    def mentions
      get_and_show "statuses/mentions.json?count=#{@num_statuses}"
    end

    def user(user = @username)
      get_and_show "statuses/user_timeline/#{user}.json?count=#{@num_statuses}"
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

    def get_and_show(rest_url)
      @io.show_statuses JSON.parse(get(rest_url))
    end

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
