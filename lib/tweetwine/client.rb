require "json"
require "uri"

module Tweetwine
  class Client
    Dependencies = Struct.new :io, :http_client, :url_shortener

    attr_reader :num_statuses, :page_num

    COMMANDS = [:home, :mentions, :user, :update, :friends, :followers]

    DEFAULT_NUM_STATUSES = 20
    DEFAULT_PAGE_NUM = 1
    MAX_STATUS_LENGTH = 140

    def initialize(dependencies, options)
      @io = dependencies.io
      @username = options[:username].to_s
      raise ArgumentError, "No authentication data given" if @username.empty?
      @http_resource = dependencies.http_client.as_resource("https://twitter.com", :user => @username, :password => options[:password])
      @num_statuses = Util.parse_int_gt(options[:num_statuses], DEFAULT_NUM_STATUSES, 1, "number of statuses_to_show")
      @page_num = Util.parse_int_gt(options[:page_num], DEFAULT_PAGE_NUM, 1, "page number")
      @url_shortener = if options[:shorten_urls] && options[:shorten_urls][:enable]
        dependencies.url_shortener.call(options[:shorten_urls])
      else
        nil
      end
      @status_update_factory = StatusUpdateFactory.new(@io, @url_shortener)
    end

    def home
      show_statuses(send_get_request("statuses/friends_timeline", :num_statuses, :page))
    end

    def mentions
      show_statuses(send_get_request("statuses/mentions", :num_statuses, :page))
    end

    def user(user = @username)
      show_statuses(send_get_request("statuses/user_timeline/#{user}", :num_statuses, :page))
    end

    def update(new_status = nil)
      new_status = @status_update_factory.create(new_status)
      completed = false
      unless new_status.empty?
        @io.show_status_preview(new_status)
        if @io.confirm("Really send?")
          status = send_post_request("statuses/update", { :status => new_status.to_s })
          @io.info "Sent status update.\n\n"
          show_statuses([status])
          completed = true
        end
      end
      @io.info "Cancelled." unless completed
    end

    def friends
      show_users(send_get_request("statuses/friends/#{@username}", :page))
    end

    def followers
      show_users(send_get_request("statuses/followers/#{@username}", :page))
    end

    private

    def send_get_request(sub_url, *query_opts)
      JSON.parse(@http_resource[sub_url + ".json?#{create_query_string(query_opts)}"].get)
    end

    def send_post_request(sub_url, payload)
      JSON.parse(@http_resource[sub_url + ".json"].post(payload))
    end

    def create_query_string(query_opts)
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
        @io.show_record(parse_response(user_data, status_data))
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

    class StatusUpdateFactory
      def initialize(io, url_shortener)
        @io = io
        @url_shortener = url_shortener
      end

      def create(status)
        StatusUpdate.new(status, @io, @url_shortener).to_s
      end
    end

    class StatusUpdate
      def initialize(status, io, url_shortener)
        @io = io
        @url_shortener = url_shortener
        @text = prepare(status)
      end

      def to_s
        @text.to_s
      end

      private

      def prepare(status)
        status = unless status
          @io.prompt("Status update")
        else
          status.dup
        end
        status.strip!
        shorten_urls!(status) if @url_shortener
        truncate!(status) if status.length > MAX_STATUS_LENGTH
        status
      end

      def truncate!(status)
        status.replace status[0...MAX_STATUS_LENGTH]
        @io.warn("Status will be truncated.")
      end

      def shorten_urls!(status)
        url_pairs = URI.extract(status, ["http", "https"]).uniq.map do |url_to_be_shortened|
          [url_to_be_shortened, @url_shortener.shorten(url_to_be_shortened)]
        end
        url_pairs.reject { |pair| pair.last.nil? || pair.last.empty? }.each do |url_pair|
          status.gsub!(url_pair.first, url_pair.last)
        end
      rescue HttpError, LoadError => e
        @io.warn "#{e}. Skipping URL shortening..."
      end
    end
  end
end
