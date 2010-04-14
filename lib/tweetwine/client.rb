# coding: utf-8

require "json"
require "uri"

module Tweetwine
  class Client
    Dependencies = Struct.new :io, :http_client, :url_shortener

    COMMANDS = [:followers, :friends, :home, :mentions, :search, :update, :user]
    DEFAULT_COMMAND = :home

    DEFAULT_NUM_STATUSES = 20
    DEFAULT_PAGE_NUM = 1
    MAX_STATUS_LENGTH = 140

    attr_reader :num_statuses, :page_num

    def initialize(dependencies, options)
      @io = dependencies.io
      @username = options[:username].to_s
      raise ArgumentError, "No authentication data given" if @username.empty?
      RetryingHttp.proxy = options[:http_proxy] if options[:http_proxy]
      @http_client = dependencies.http_client
      @http_resource = @http_client.as_resource("https://twitter.com", :user => @username, :password => options[:password])
      @num_statuses = Util.parse_int_gt(options[:num_statuses], DEFAULT_NUM_STATUSES, 1, "number of statuses_to_show")
      @page_num = Util.parse_int_gt(options[:page_num], DEFAULT_PAGE_NUM, 1, "page number")
      @url_shortener = if options[:shorten_urls] && options[:shorten_urls][:enable]
        dependencies.url_shortener.call(options[:shorten_urls])
      end
    end

    def followers(args = [], options = nil)
      response = get_from_rest_api("statuses/followers/#{@username}")
      show_users_from_rest_api(*response)
    end

    def friends(args = [], options = nil)
      response = get_from_rest_api("statuses/friends/#{@username}")
      show_users_from_rest_api(*response)
    end

    def home(args = [], options = nil)
      response = get_from_rest_api("statuses/home_timeline", :num_statuses, :page)
      show_statuses_from_rest_api(*response)
    end

    def mentions(args = [], options = nil)
      response = get_from_rest_api("statuses/mentions", :num_statuses, :page)
      show_statuses_from_rest_api(*response)
    end

    def search(args = [], options = nil)
      raise ArgumentError, "No search word" if args.empty?
      query = if options && options[:bin_op] == :or then args.join(" OR ") else args.join(" ") end
      response = get_from_search_api(query, :num_statuses, :page)
      show_statuses_from_search_api(*response["results"])
    end

    def update(args = [], options = nil)
      new_status = create_status_update(args.join(" "))
      completed = false
      unless new_status.empty?
        @io.show_status_preview(new_status)
        if @io.confirm("Really send?")
          response = post_to_rest_api("statuses/update", :status => new_status.to_s)
          @io.info "Sent status update.\n\n"
          show_statuses_from_rest_api(response)
          completed = true
        end
      end
      @io.info "Cancelled." unless completed
    end

    def user(args = [], options = nil)
      user = if args.empty? then @username else args.first end
      response = get_from_rest_api("statuses/user_timeline/#{user}", :num_statuses, :page)
      show_statuses_from_rest_api(*response)
    end

    private

    def get_from_rest_api(sub_url, *query_opts)
      query_str = query_options_to_string(query_opts, :page => "page", :num_statuses => "count")
      url_suffix = unless query_str.empty? then "?" << query_str else "" end
      JSON.parse(@http_resource[sub_url + ".json" + url_suffix].get)
    end

    def post_to_rest_api(sub_url, payload)
      JSON.parse(@http_resource[sub_url + ".json"].post(payload))
    end

    def get_from_search_api(query, *query_opts)
      query_str = "q=#{Util.percent_encode(query)}&" \
                << query_options_to_string(query_opts, :page => "page", :num_statuses => "rpp")
      JSON.parse(@http_client.get("http://search.twitter.com/search.json?#{query_str}"))
    end

    def query_options_to_string(query_opts, key_mappings)
      pairs = []
      query_opts.each do |opt|
        case opt
        when :page
          pairs << "#{key_mappings[:page]}=#{@page_num}"
        when :num_statuses
          pairs << "#{key_mappings[:num_statuses]}=#{@num_statuses}"
        # else: ignore unknown query options
        end
      end
      pairs.join("&")
    end

    def show_statuses_from_rest_api(*responses)
      show_records(
        responses,
        {
          :from_user  => ["user", "screen_name"],
          :to_user    => "in_reply_to_screen_name",
          :created_at => "created_at",
          :status     => "text"
        }
      )
    end

    def show_users_from_rest_api(*responses)
      show_records(
        responses,
        {
          :from_user  => "screen_name",
          :to_user    => ["status", "in_reply_to_screen_name"],
          :created_at => ["status", "created_at"],
          :status     => ["status", "text"]
        }
      )
    end

    def show_statuses_from_search_api(*responses)
      show_records(
        responses,
        {
          :from_user  => "from_user",
          :to_user    => "to_user",
          :created_at => "created_at",
          :status     => "text"
        }
      )
    end

    def show_records(twitter_records, paths)
      twitter_records.each do |twitter_record|
        internal_record = [ :from_user, :to_user, :created_at, :status ].inject({}) do |result, key|
          result[key] = Util.find_hash_path(twitter_record, paths[key])
          result
        end
        @io.show_record(internal_record)
      end
    end

    def create_status_update(status)
      status = if status.nil? || status.empty?
        @io.prompt("Status update")
      else
        status.dup
      end
      status.strip!
      shorten_urls_in(status) if @url_shortener
      truncate_status(status) if status.length > MAX_STATUS_LENGTH
      status
    end

    def shorten_urls_in(status)
      url_pairs = URI.extract(status, ["http", "https"]).uniq.map do |url_to_be_shortened|
        [url_to_be_shortened, @url_shortener.shorten(url_to_be_shortened)]
      end
      url_pairs.reject { |pair| pair.last.nil? || pair.last.empty? }.each do |url_pair|
        status.gsub!(url_pair.first, url_pair.last)
      end
    rescue HttpError, LoadError => e
      @io.warn "#{e}. Skipping URL shortening..."
    end

    def truncate_status(status)
      status.replace status[0...MAX_STATUS_LENGTH]
      @io.warn("Status will be truncated.")
    end
  end
end
