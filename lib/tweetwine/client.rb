require "json"
require "rest_client"

module Tweetwine
  class ClientError < RuntimeError; end

  class Client
    attr_reader :num_statuses, :page_num

    COMMANDS = [:home, :mentions, :user, :update, :friends, :followers]

    DEFAULT_NUM_STATUSES = 20
    DEFAULT_PAGE_NUM = 1
    MAX_STATUS_LENGTH = 140

    def initialize(options)
      @username = options[:username].to_s
      raise ArgumentError, "No authentication data given" if @username.empty?
      @base_url = "https://#{@username}:#{options[:password]}@twitter.com/"
      @colorize = options[:colorize] || false
      @num_statuses = parse_int_gt_option(options[:num_statuses], DEFAULT_NUM_STATUSES, 1, "number of statuses_to_show")
      @page_num = parse_int_gt_option(options[:page_num], DEFAULT_PAGE_NUM, 1, "page number")
      @io = IO.new(options)
    end

    def home
      show_statuses(get_response_as_json("statuses/friends_timeline", :num_statuses, :page))
    end

    def mentions
      show_statuses(get_response_as_json("statuses/mentions", :num_statuses, :page))
    end

    def user(user = @username)
      show_statuses(get_response_as_json("statuses/user_timeline/#{user}", :num_statuses, :page))
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
        show_statuses([status])
      else
        @io.info "Cancelled."
      end
    end

    def friends
      show_users(get_response_as_json("statuses/friends/#{@username}", :page))
    end

    def followers
      show_users(get_response_as_json("statuses/followers/#{@username}", :page))
    end

    private

    def parse_int_gt_option(value, default, min, name_for_error)
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

    def get_response_as_json(url_body, *query_opts)
      url = url_body + ".json?#{parse_query_options(query_opts)}"
      JSON.parse(get(url))
    end

    def parse_query_options(query_opts)
      str = []
      query_opts.each do |opt|
        case opt
        when :page
          str << "page=#{@page_num}"
        when :num_statuses
          str << "count=#{@num_statuses}"
        # do nothing on else
        end
      end
      str.join("&")
    end

    def show_statuses(data)
      show_responses(data) { |entry| [entry["user"], entry] }
    end

    def show_users(data)
      show_responses(data) { |entry| [entry, entry["status"]] }
    end

    def show_responses(data)
      data.each do |entry|
        user_data, status_data = yield entry
        @io.show(parse_response(user_data, status_data))
      end
    end

    def parse_response(user_data, status_data)
      record = { :user => user_data["screen_name"] }
      if status_data
        record[:status] = {
          :created_at  => status_data["created_at"],
          :in_reply_to => status_data["in_reply_to_screen_name"],
          :text        => status_data["text"]
        }
      end
      record
    end

    def get(body_url)
      rest_client_action(:get, @base_url + body_url)
    end

    def post(body_url, body)
      rest_client_action(:post, @base_url + body_url, body)
    end

    def rest_client_action(action, *args)
      RestClient.send(action, *args)
    rescue RestClient::Exception, SystemCallError => e
      raise ClientError, e.message
    end
  end
end
