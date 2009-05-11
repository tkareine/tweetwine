require "json"
require "rest_client"

module Tweetwine
  class ClientError < RuntimeError; end

  class Client
    attr_reader :num_statuses, :page_num

    COMMANDS = [:home, :mentions, :user, :update]

    DEFAULT_NUM_STATUSES = 20
    DEFAULT_PAGE_NUM = 1
    MAX_STATUS_LENGTH = 140

    def initialize(options)
      @username = options[:username].to_s
      raise ArgumentError, "No authentication data given" if @username.empty?
      @base_url = "https://#{@username}:#{options[:password]}@twitter.com/"
      @colorize = options[:colorize] || false
      @num_statuses = parse_positive_int_option(options[:num_statuses], DEFAULT_NUM_STATUSES, 1, "number of statuses_to_show")
      @page_num = parse_positive_int_option(options[:page_num], DEFAULT_PAGE_NUM, 1, "page number")
      @io = IO.new(options)
    end

    def home
      get_result_as_json_and_show "statuses/friends_timeline"
    end

    def mentions
      get_result_as_json_and_show "statuses/mentions"
    end

    def user(user = @username)
      get_result_as_json_and_show "statuses/user_timeline/#{user}"
    end

    def update(new_status = nil)
      new_status = @io.prompt("Status update") unless new_status
      if new_status.length > MAX_STATUS_LENGTH
        new_status = new_status[0...MAX_STATUS_LENGTH]
        @io.warn("Status will be truncated: #{new_status}")
      end
      if !new_status.empty? && @io.confirm("Really send?")
        status = JSON.parse(post("statuses/update.json", {:status => new_status}))
        @io.info "Sent status update.\n\n"
        @io.show_statuses([status])
      else
        @io.info "Cancelled."
      end
    end

    private

    def parse_positive_int_option(value, default, min, name_for_error)
      if value
        value = value.to_i
        if value >= min
          value
        else
          raise ArgumentError, "Invalid #{name_for_error} -- must be greater than or equal to #{min}"
        end
      else
        default
      end
    end

    def get_result_as_json_and_show(url_body)
      @io.show_statuses JSON.parse(get(url_body + ".json?count=#{@num_statuses}&page=#{@page_num}"))
    end

    def get(body_url)
      rest_client_action(:get, @base_url + body_url)
    end

    def post(body_url, body)
      rest_client_action(:post, @base_url + body_url, body)
    end

    def rest_client_action(action, *args)
      RestClient.send(action, *args)
    rescue RestClient::Exception => e
      raise ClientError, e.message
    end
  end
end
