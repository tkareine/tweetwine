# coding: utf-8

require "uri"

module Tweetwine
  class Twitter
    MAX_STATUS_LENGTH = 140

    REST_API_STATUS_PATHS = {
      :from_user  => %w{user screen_name},
      :to_user    => %w{in_reply_to_screen_name},
      :retweet    => %w{retweeted_status},
      :created_at => %w{created_at},
      :status     => %w{text}
    }

    REST_API_USER_PATHS = {
      :from_user  => %w{screen_name},
      :to_user    => %w{status in_reply_to_screen_name},
      :retweet    => %w{retweeted_status},
      :created_at => %w{status created_at},
      :status     => %w{status text}
    }

    SEARCH_API_STATUS_PATHS = {
      :from_user  => %w{from_user},
      :to_user    => %w{to_user},
      :retweet    => %w{retweeted_status},
      :created_at => %w{created_at},
      :status     => %w{text}
    }

    attr_reader :num_tweets, :page, :username

    def initialize(options = {})
      @num_tweets = Support.parse_int_gt(options[:num_tweets], CLI::DEFAULT_CONFIG[:num_tweets], 1, "number of tweets to show")
      @page       = Support.parse_int_gt(options[:page], CLI::DEFAULT_CONFIG[:page], 1, "page number")
      @username   = options[:username].to_s
    end

    def followers
      show_users_from_rest_api(get_from_rest_api("statuses/followers"))
    end

    def friends
      show_users_from_rest_api(get_from_rest_api("statuses/friends"))
    end

    def home
      show_statuses_from_rest_api(get_from_rest_api("statuses/home_timeline"))
    end

    def mentions
      show_statuses_from_rest_api(get_from_rest_api("statuses/mentions"))
    end

    def search(words = [], operator = nil)
      raise ArgumentError, "No search words" if words.empty?
      operator = :and unless operator
      query = operator == :and ? words.join(' ') : words.join(' OR ')
      response = get_from_search_api query
      show_statuses_from_search_api(response["results"])
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
          show_statuses_from_rest_api([response])
          completed = true
        end
      end
      CLI.ui.info "Cancelled." unless completed
    end

    def user(who = username)
      show_statuses_from_rest_api(get_from_rest_api(
        "statuses/user_timeline",
        common_rest_api_query_params.merge!({ :screen_name => who })
      ))
    end

    private

    def common_rest_api_query_params
      {
        :count => @num_tweets,
        :page  => @page
      }
    end

    def common_search_api_query_params
      {
        :rpp  => @num_tweets,
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
      query = format_query_params(params)
      url_suffix = query.empty? ? "" : "?" << query
      resource = rest_api["#{sub_url}.json#{url_suffix}"]
      authorize_on_demand do
        JSON.parse resource.get(&CLI.oauth.request_signer)
      end
    end

    def post_to_rest_api(sub_url, payload)
      resource = rest_api["#{sub_url}.json"]
      authorize_on_demand do
        JSON.parse resource.post(payload, &CLI.oauth.request_signer)
      end
    end

    def get_from_search_api(query, params = common_search_api_query_params)
      query = "q=#{Uri.percent_encode(query)}&" << format_query_params(params)
      JSON.parse search_api["search.json?#{query}"].get
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

    def show_statuses_from_rest_api(records)
      show_records(records, REST_API_STATUS_PATHS)
    end

    def show_users_from_rest_api(records)
      show_records(records, REST_API_USER_PATHS)
    end

    def show_statuses_from_search_api(records)
      show_records(records, SEARCH_API_STATUS_PATHS)
    end

    def show_records(records, paths)
      records.
        map   { |record| Tweet.new(record, paths) }.
        each  { |tweet|  CLI.ui.show_tweet(tweet) }
    end

    def create_status_update(status)
      status = if Support.blank? status
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
      url_pairs = Uri.
          extract(status, %w{http https}).
          uniq.
          map { |full_url| [full_url, CLI.url_shortener.shorten(full_url)] }.
          reject { |(full_url, short_url)| Support.blank? short_url }
      url_pairs.each { |(full_url, short_url)| status.gsub!(full_url, short_url) }
    rescue HttpError, LoadError => e
      CLI.ui.warn "#{e}\nSkipping URL shortening..."
    end

    def truncate_status(status)
      status.replace status[0...MAX_STATUS_LENGTH]
      CLI.ui.warn("Status will be truncated.")
    end
  end
end
