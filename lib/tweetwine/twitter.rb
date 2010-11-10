# coding: utf-8

require "json"
require "uri"

module Tweetwine
  class Twitter
    DEFAULT_NUM_STATUSES = 20
    DEFAULT_PAGE_NUM = 1
    MAX_STATUS_LENGTH = 140

    attr_reader :num_statuses, :page, :username

    def initialize(options = {})
      @num_statuses = Util.parse_int_gt(options[:num_statuses], DEFAULT_NUM_STATUSES, 1, "number of statuses_to_show")
      @page         = Util.parse_int_gt(options[:page], DEFAULT_PAGE_NUM, 1, "page number")
      @username     = options[:username].to_s
    end

    def followers
      response = get_from_rest_api "statuses/followers"
      show_users_from_rest_api(*response)
    end

    def friends
      response = get_from_rest_api "statuses/friends"
      show_users_from_rest_api(*response)
    end

    def home
      response = get_from_rest_api "statuses/home_timeline"
      show_statuses_from_rest_api(*response)
    end

    def mentions
      response = get_from_rest_api "statuses/mentions"
      show_statuses_from_rest_api(*response)
    end

    def search(words = [], operator = nil)
      raise ArgumentError, "No search words" if words.empty?
      operator = :and unless operator
      query = operator == :and ? words.join(' ') : words.join(' OR ')
      response = get_from_search_api query
      show_statuses_from_search_api(*response["results"])
    end

    def update(msg = nil)
      new_status = create_status_update(msg)
      completed = false
      unless new_status.empty?
        CLI.ui.show_status_preview(new_status)
        status_in_utf8 = CharacterEncoding.to_utf8 new_status
        if CLI.ui.confirm("Really send?")
          response = post_to_rest_api("statuses/update", :status => status_in_utf8)
          CLI.ui.info "Sent status update.\n\n"
          show_statuses_from_rest_api response
          completed = true
        end
      end
      CLI.ui.info "Cancelled." unless completed
    end

    def user(who = username)
      response = get_from_rest_api(
        "statuses/user_timeline",
        common_rest_api_query_params.merge!({ :screen_name => who })
      )
      show_statuses_from_rest_api(*response)
    end

    private

    def common_rest_api_query_params
      {
        :count => @num_statuses,
        :page  => @page
      }
    end

    def common_search_api_query_params
      {
        :rpp  => @num_statuses,
        :page => @page
      }
    end

    def format_query_params(params)
      params.each_pair.map { |k, v| "#{k}=#{v}" }.sort.join('&')
    end

    def rest_api
      @rest_api ||= CLI.http.as_resource "https://api.twitter.com/1"
    end

    def search_api
      @search_api ||= CLI.http.as_resource "http://search.twitter.com"
    end

    def get_from_rest_api(sub_url, params = common_rest_api_query_params)
      authorize_on_demand do
        query = format_query_params(params)
        url_suffix = query.empty? ? "" : "?" << query
        response = rest_api[sub_url + ".json" + url_suffix].get(&CLI.oauth.request_signer)
        JSON.parse response
      end
    end

    def post_to_rest_api(sub_url, payload)
      authorize_on_demand do
        response = rest_api[sub_url + ".json"].post(payload, &CLI.oauth.request_signer)
        JSON.parse response
      end
    end

    def get_from_search_api(query, params = common_search_api_query_params)
      query = "q=#{Util.percent_encode(query)}&" << format_query_params(params)
      response = search_api["search.json?#{query}"].get
      JSON.parse response
    end

    def authorize_on_demand
      yield
    rescue HttpError => e
      if e.http_code == 401
        CLI.oauth.authorize { |access_token| save_config_with_access_token(access_token) }
        retry
      else
        raise
      end
    end

    def save_config_with_access_token(token)
      CLI.config[:oauth_access] = token
      CLI.config.save
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
        CLI.ui.show_record(internal_record)
      end
    end

    def create_status_update(status)
      status = if Util.blank? status
        CLI.ui.prompt("Status update")
      else
        status.dup
      end
      status.strip!
      shorten_urls_in(status) if CLI.config[:shorten_urls] && !CLI.config[:shorten_urls][:disable]
      truncate_status(status) if status.length > MAX_STATUS_LENGTH
      status
    end

    def shorten_urls_in(status)
      url_pairs = URI.extract(status, ["http", "https"]).uniq.map do |url_to_be_shortened|
        [url_to_be_shortened, CLI.url_shortener.shorten(url_to_be_shortened)]
      end
      url_pairs.reject { |pair| Util.blank? pair.last }.each do |url_pair|
        status.gsub!(url_pair.first, url_pair.last)
      end
    rescue HttpError, LoadError => e
      CLI.ui.warn "#{e}\nSkipping URL shortening..."
    end

    def truncate_status(status)
      status.replace status[0...MAX_STATUS_LENGTH]
      CLI.ui.warn("Status will be truncated.")
    end
  end
end
