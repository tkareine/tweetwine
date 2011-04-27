# coding: utf-8

require 'unit/helper'

module Tweetwine::Test::Unit

class ClientTest < TestCase
  before do
    @config = {
      :num_tweets => 20,
      :page       => 1
    }
    stub_config @config
  end

  describe "for initialization" do
    it "uses default number of statuses if not configured" do
      @twitter = Twitter.new
      assert_equal @config[:num_tweets], @twitter.num_tweets
    end

    it "uses configured number of statuses if in allowed range" do
      @twitter = Twitter.new(:num_tweets => 12)
      assert_equal 12, @twitter.num_tweets
    end

    it "raises exception if configured number of status not in allowed range" do
      assert_raises(CommandLineError) { Twitter.new(:num_tweets => 0) }
    end

    it "uses default page number if not configured otherwise" do
      @twitter = Twitter.new
      assert_equal @config[:page], @twitter.page
    end

    it "uses configured page number if in allowed range" do
      @twitter = Twitter.new(:page => 12)
      assert_equal 12, @twitter.page
    end

    it "raises exception if configured page number not in allowed range" do
      assert_raises(CommandLineError) { Twitter.new(:page => 0) }
    end
  end

  describe "at runtime" do
    before do
      mock_http
      mock_oauth
      mock_ui
      @username = "spiky"
      @rest_api = mock("Http's REST API")
      @search_api = mock("Http's Search API")
      @http.stubs(:as_resource).with("https://api.twitter.com/1").returns(@rest_api)
      @http.stubs(:as_resource).with("http://search.twitter.com").returns(@search_api)
      @twitter = Twitter.new(:username => @username)
      @rest_api_status_query_str = "count=#{@config[:num_tweets]}&page=#{@config[:page]}"
      @search_api_query_str = "page=#{@config[:page]}&rpp=#{@config[:num_tweets]}"
    end

    it "skips showing an invalid tweet" do
      invalid_from_user = nil
      twitter_records, internal_records = create_rest_api_status_records(
        {
          :from_user  => invalid_from_user,
          :status     => "wassup?"
        },
        {
          :from_user  => "lulzwoo",
          :status     => "nuttin'"
        }
      )
      @oauth.expects(:request_signer)
      @rest_api.expects(:[]).
        with("statuses/home_timeline.json?#{@rest_api_status_query_str}").
        returns(stub(:get => twitter_records.to_json))
      @ui.expects(:warn).with("Invalid tweet. Skipping...")
      @ui.expects(:show_tweets).with(internal_records[1..-1])
      @twitter.home
    end

    it "fetches friends' statuses (home view)" do
      twitter_records, internal_records = create_rest_api_status_records(
        {
          :from_user  => "zanzibar",
          :status     => "wassup?"
        },
        {
          :from_user  => "lulzwoo",
          :status     => "nuttin'"
        }
      )
      @oauth.expects(:request_signer)
      @rest_api.expects(:[]).
        with("statuses/home_timeline.json?#{@rest_api_status_query_str}").
        returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_tweets).with(internal_records)
      @twitter.home
    end

    it "fetches mentions" do
      twitter_records, internal_records = create_rest_api_status_records(
        {
          :from_user  => "zanzibar",
          :status     => "wassup, @#{@username}?",
          :to_user    => @username
        },
        {
          :from_user  => "lulzwoo",
          :status     => "@#{@username}, doing nuttin'",
          :to_user    => @username
        }
      )
      @oauth.expects(:request_signer)
      @rest_api.expects(:[]).
        with("statuses/mentions.json?#{@rest_api_status_query_str}").
        returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_tweets).with(internal_records)
      @twitter.mentions
    end

    it "fetches a specific user's statuses, when user is given as argument" do
      username = "spoonman"
      twitter_records, internal_records = create_rest_api_status_records({
        :from_user  => username,
        :status     => "wassup?"
      })
      @oauth.expects(:request_signer)
      @rest_api.expects(:[]).
        with("statuses/user_timeline.json?#{@rest_api_status_query_str}&screen_name=#{username}").
        returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_tweets).with(internal_records)
      @twitter.user(username)
    end

    it "fetches a specific user's statuses, with user being the authenticated user itself when given no argument" do
      twitter_records, internal_records = create_rest_api_status_records({
        :from_user  => @username,
        :status     => "wassup?"
      })
      @oauth.expects(:request_signer)
      @rest_api.expects(:[]).
        with("statuses/user_timeline.json?#{@rest_api_status_query_str}&screen_name=#{@username}").
        returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_tweets).with(internal_records)
      @twitter.user
    end

    it "posts a status update via argument, when positive confirmation" do
      status = "wondering around"
      twitter_records, internal_records = create_rest_api_status_records({
        :from_user  => @username,
        :status     => status
      })
      @oauth.expects(:request_signer)
      http_subresource = mock
      http_subresource.expects(:post).
        with({ :status => status }).
        returns(twitter_records[0].to_json)
      @rest_api.expects(:[]).
        with("statuses/update.json").
        returns(http_subresource)
      @ui.expects(:confirm).with("Really send?").returns(true)
      @ui.expects(:show_status_preview).with(status)
      @ui.expects(:info).with("Sent status update.\n\n")
      @ui.expects(:show_tweets).with(internal_records)
      @twitter.update(status)
    end

    it "posts a status update via prompt, when positive confirmation" do
      status = "wondering around"
      twitter_records, internal_records = create_rest_api_status_records({
        :from_user  => @username,
        :status     => status
      })
      @oauth.expects(:request_signer)
      http_subresource = mock
      http_subresource.expects(:post).
        with({ :status => status }).
        returns(twitter_records[0].to_json)
      @rest_api.expects(:[]).
        with("statuses/update.json").
        returns(http_subresource)
      @ui.expects(:prompt).with("Status update").returns(status)
      @ui.expects(:show_status_preview).with(status)
      @ui.expects(:confirm).with("Really send?").returns(true)
      @ui.expects(:info).with("Sent status update.\n\n")
      @ui.expects(:show_tweets).with(internal_records)
      @twitter.update
    end

    it "cancels a status update via argument, when negative confirmation" do
      status = "wondering around"
      @rest_api.expects(:[]).never
      @ui.expects(:show_status_preview).with(status)
      @ui.expects(:confirm).with("Really send?").returns(false)
      @ui.expects(:info).with("Cancelled.")
      @ui.expects(:show_tweets).never
      @twitter.update(status)
    end

    it "cancels a status update via prompt, when negative confirmation" do
      status = "wondering around"
      @rest_api.expects(:[]).never
      @ui.expects(:prompt).with("Status update").returns(status)
      @ui.expects(:show_status_preview).with(status)
      @ui.expects(:confirm).with("Really send?").returns(false)
      @ui.expects(:info).with("Cancelled.")
      @ui.expects(:show_tweets).never
      @twitter.update
    end

    it "cancels a status update via argument, when empty status" do
      @rest_api.expects(:[]).never
      @ui.expects(:prompt).with("Status update").returns("")
      @ui.expects(:confirm).never
      @ui.expects(:info).with("Cancelled.")
      @ui.expects(:show_tweets).never
      @twitter.update("")
    end

    it "cancels a status update via prompt, when empty status" do
      @rest_api.expects(:[]).never
      @ui.expects(:prompt).with("Status update").returns("")
      @ui.expects(:confirm).never
      @ui.expects(:info).with("Cancelled.")
      @ui.expects(:show_tweets).never
      @twitter.update
    end

    it "removes excess whitespace around a status update" do
      whitespaced_status = "  oh, i was sloppy \t   "
      stripped_status = "oh, i was sloppy"
      twitter_records, internal_records = create_rest_api_status_records({
        :from_user  => @username,
        :status     => stripped_status
      })
      @oauth.expects(:request_signer)
      http_subresource = mock
      http_subresource.expects(:post).
        with({ :status => stripped_status }).
        returns(twitter_records[0].to_json)
      @rest_api.expects(:[]).
        with("statuses/update.json").
        returns(http_subresource)
      @ui.expects(:show_status_preview).with(stripped_status)
      @ui.expects(:confirm).with("Really send?").returns(true)
      @ui.expects(:info).with("Sent status update.\n\n")
      @ui.expects(:show_tweets).with(internal_records)
      @twitter.update(whitespaced_status)
    end

    it "truncates a status update with too long argument and warn the user" do
      truncated_status = "ab c" * 35  #  4 * 35 = 140
      long_status = "#{truncated_status} dd"
      twitter_records, internal_records = create_rest_api_status_records({
        :from_user  => @username,
        :status     => truncated_status
      })
      @oauth.expects(:request_signer)
      http_subresource = mock
      http_subresource.expects(:post).
        with({ :status => truncated_status }).
        returns(twitter_records[0].to_json)
      @rest_api.expects(:[]).
        with("statuses/update.json").
        returns(http_subresource)
      @ui.expects(:warn).with("Status will be truncated.")
      @ui.expects(:show_status_preview).with(truncated_status)
      @ui.expects(:confirm).with("Really send?").returns(true)
      @ui.expects(:info).with("Sent status update.\n\n")
      @ui.expects(:show_tweets).with(internal_records)
      @twitter.update(long_status)
    end

    if defined? Encoding
      it "encodes status in UTF-8 (String supports encoding)" do
        status_utf8, status_latin1 = "résumé", "résumé".encode('ISO-8859-1')
        twitter_records, internal_records = create_rest_api_status_records({
          :from_user  => @username,
          :status     => status_utf8
        })
        @oauth.expects(:request_signer)
        http_subresource = mock
        http_subresource.expects(:post).
          with({ :status => status_utf8 }).
          returns(twitter_records[0].to_json)
        @rest_api.expects(:[]).
          with("statuses/update.json").
          returns(http_subresource)
        @ui.expects(:confirm).with("Really send?").returns(true)
        @ui.expects(:show_status_preview).with(status_latin1)
        @ui.expects(:info).with("Sent status update.\n\n")
        @ui.expects(:show_tweets).with(internal_records)
        @twitter.update(status_latin1)
      end
    else
      it "encodes status in UTF-8 (String does not support encoding)" do
        CharacterEncoding.forget_guess
        tmp_kcode('NONE') do
          tmp_env(:LANG => 'ISO-8859-1') do
            status_utf8, status_latin1 = "r\xc3\xa9sum\xc3\xa9", "r\xe9sum\xe9"
            twitter_records, internal_records = create_rest_api_status_records({
              :from_user  => @username,
              :status     => status_utf8
            })
            @oauth.expects(:request_signer)
            http_subresource = mock
            http_subresource.expects(:post).
              with({ :status => status_utf8 }).
              returns(twitter_records[0].to_json)
            @rest_api.expects(:[]).
              with("statuses/update.json").
              returns(http_subresource)
            @ui.expects(:confirm).with("Really send?").returns(true)
            @ui.expects(:show_status_preview).with(status_latin1)
            @ui.expects(:info).with("Sent status update.\n\n")
            @ui.expects(:show_tweets).with(internal_records)
            @twitter.update(status_latin1)
          end
        end
      end
    end

    describe "with URL shortening" do
      before do
        mock_url_shortener
        stub_config(
          :shorten_urls => {
            :service_url    => "http://shorten.it/create",
            :method         => "post",
            :url_param_name => "url",
            :xpath_selector => "//input[@id='short_url']/@value"
          })
      end

      it "does not shorten URLs if not configured" do
        stub_config
        status = "reading http://www.w3.org/TR/1999/REC-xpath-19991116"
        twitter_records, internal_records = create_rest_api_status_records({
          :from_user  => @username,
          :status     => status
        })
        @oauth.expects(:request_signer)
        http_subresource = mock
        http_subresource.expects(:post).
          with({ :status => status }).
          returns(twitter_records[0].to_json)
        @url_shortener.expects(:shorten).never
        @rest_api.expects(:[]).
          with("statuses/update.json").
          returns(http_subresource)
        @ui.expects(:confirm).with("Really send?").returns(true)
        @ui.expects(:show_status_preview).with(status)
        @ui.expects(:info).with("Sent status update.\n\n")
        @ui.expects(:show_tweets).with(internal_records)
        @twitter.update(status)
      end

      it "shortens HTTP and HTTPS URLs" do
        long_urls = ["http://www.google.fi/search?q=ruby+nokogiri&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a", "https://twitter.com/#!/messages"]
        long_status = long_urls.join(" and ")
        short_urls = ["http://shorten.it/2k7i8", "http://shorten.it/2k7mk"]
        shortened_status = short_urls.join(" and ")
        twitter_records, internal_records = create_rest_api_status_records({
          :from_user  => @username,
          :status     => shortened_status
        })
        @oauth.expects(:request_signer)
        http_subresource = mock
        http_subresource.expects(:post).
          with({ :status => shortened_status }).
          returns(twitter_records[0].to_json)
        @rest_api.expects(:[]).
          with("statuses/update.json").
          returns(http_subresource)
        @url_shortener.expects(:shorten).with(long_urls.first).returns(short_urls.first)
        @url_shortener.expects(:shorten).with(long_urls.last).returns(short_urls.last)
        @ui.expects(:show_status_preview).with(shortened_status)
        @ui.expects(:confirm).with("Really send?").returns(true)
        @ui.expects(:info).with("Sent status update.\n\n")
        @ui.expects(:show_tweets).with(internal_records)
        @twitter.update(long_status)
      end

      it "discards obviously invalid shortened URLs, using originals instead" do
        long_urls = ["http://www.google.fi/", "http://www.w3.org/TR/1999/REC-xpath-19991116"]
        status = long_urls.join(" and ")
        short_urls = [nil, ""]
        twitter_records, internal_records = create_rest_api_status_records({
          :from_user  => @username,
          :status     => status
        })
        @oauth.expects(:request_signer)
        http_subresource = mock
        http_subresource.expects(:post).
          with({ :status => status }).
          returns(twitter_records[0].to_json)
        @rest_api.expects(:[]).
          with("statuses/update.json").
          returns(http_subresource)
        @url_shortener.expects(:shorten).with(long_urls.first).returns(short_urls.first)
        @url_shortener.expects(:shorten).with(long_urls.last).returns(short_urls.last)
        @ui.expects(:show_status_preview).with(status)
        @ui.expects(:confirm).with("Really send?").returns(true)
        @ui.expects(:info).with("Sent status update.\n\n")
        @ui.expects(:show_tweets).with(internal_records)
        @twitter.update(status)
      end

      it "reuses a shortened URL for duplicate long URLs" do
        long_urls = ["http://www.w3.org/TR/1999/REC-xpath-19991116"] * 2
        long_status = long_urls.join(" and ")
        short_url = "http://shorten.it/2k7mk"
        short_status = ([short_url] * 2).join(" and ")
        twitter_records, internal_records = create_rest_api_status_records({
          :from_user  => @username,
          :status     => short_status
        })
        @oauth.expects(:request_signer)
        http_subresource = mock
        http_subresource.expects(:post).
          with({ :status => short_status }).
          returns(twitter_records[0].to_json)
        @rest_api.expects(:[]).
          with("statuses/update.json").
          returns(http_subresource)
        @url_shortener.expects(:shorten).with(long_urls.first).returns(short_url)
        @ui.expects(:show_status_preview).with(short_status)
        @ui.expects(:confirm).with("Really send?").returns(true)
        @ui.expects(:info).with("Sent status update.\n\n")
        @ui.expects(:show_tweets).with(internal_records)
        @twitter.update(long_status)
      end

      describe "in erroneous situations" do
        before do
          @url = "http://www.w3.org/TR/1999/REC-xpath-19991116"
          @status = "skimming through #{@url}"
          @twitter_records, @internal_records = create_rest_api_status_records({
            :from_user  => @username,
            :status     => @status
          })
        end

        it "skips shortening URLs if required libraries are not found" do
          Tweetwine::CLI.stubs(:url_shortener).raises(LoadError, 'gem not found')
          @oauth.expects(:request_signer)
          http_subresource = mock
          http_subresource.expects(:post).
            with({ :status => @status }).
            returns(@twitter_records[0].to_json)
          @rest_api.expects(:[]).
            with("statuses/update.json").
            returns(http_subresource)
          @ui.expects(:warn)
          @ui.expects(:show_status_preview).with(@status)
          @ui.expects(:confirm).with("Really send?").returns(true)
          @ui.expects(:info).with("Sent status update.\n\n")
          @ui.expects(:show_tweets).with(@internal_records)
          @twitter.update(@status)
        end

        it "skips shortening URLs upon connection error to the URL shortening service" do
          @oauth.expects(:request_signer)
          http_subresource = mock
          http_subresource.expects(:post).
            with({ :status => @status }).
            returns(@twitter_records[0].to_json)
          @rest_api.expects(:[]).
            with("statuses/update.json").
            returns(http_subresource)
          @url_shortener.expects(:shorten).with(@url).raises(HttpError.new(404, "Not Found"))
          @ui.expects(:warn)
          @ui.expects(:show_status_preview).with(@status)
          @ui.expects(:confirm).with("Really send?").returns(true)
          @ui.expects(:info).with("Sent status update.\n\n")
          @ui.expects(:show_tweets).with(@internal_records)
          @twitter.update(@status)
        end
      end
    end

    it "fetches friends" do
      twitter_records, internal_records = create_rest_api_user_records(
        {
          :from_user  => "zanzibar",
          :status     => "wassup, @foo?",
          :to_user    => "foo"
        },
        {
          :from_user  => "lulzwoo",
          :status     => "@foo, doing nuttin'",
          :to_user    => "foo"
        }
      )
      @oauth.expects(:request_signer)
      @rest_api.expects(:[]).
        with("statuses/friends.json?#{@rest_api_status_query_str}").
        returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_tweets).with(internal_records)
      @twitter.friends
    end

    it "fetches followers" do
      twitter_records, internal_records = create_rest_api_user_records(
        {
          :from_user  => "zanzibar",
          :status     => "wassup, @foo?",
          :to_user    => "foo"
        },
        {
          :from_user  => "lulzwoo"
        }
      )
      @oauth.expects(:request_signer)
      @rest_api.expects(:[]).
        with("statuses/followers.json?#{@rest_api_status_query_str}").
        returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_tweets).with(internal_records)
      @twitter.followers
    end

    it "raises exception if no search word is given for searching tweets" do
      assert_raises(ArgumentError) { @twitter.search }
    end

    [
      [nil,   "no operator"],
      [:and,  "and operator"]
    ].each do |op, desc|
      it "searches tweets matching all the given words with #{desc}" do
        twitter_response, internal_records = create_search_api_status_records(
          {
            :from_user  => "zanzibar",
            :status     => "@foo, wassup? #greets",
            :to_user    => "foo"
          },
          {
            :from_user  => "spoonman",
            :status     => "@foo long time no see #greets",
            :to_user    => "foo"
          }
        )
        @search_api.expects(:[]).
          with("search.json?q=%23greets%20%40foo&#{@search_api_query_str}").
          returns(stub(:get => twitter_response.to_json))
        @ui.expects(:show_tweets).with(internal_records)
        @twitter.search(["#greets", "@foo"], op)
      end
    end

    it "searches tweets matching any of the given words with or operator" do
      twitter_response, internal_records = create_search_api_status_records(
        {
          :from_user  => "zanzibar",
          :status     => "spinning around the floor #habits",
          :to_user    => "foo"
        },
        {
          :from_user  => "spoonman",
          :status     => "drinking coffee, again #neurotic",
          :to_user    => "foo"
        }
      )
      @search_api.expects(:[]).
        with("search.json?q=%23habits%20OR%20%23neurotic&#{@search_api_query_str}").
        returns(stub(:get => twitter_response.to_json))
      @ui.expects(:show_tweets).with(internal_records)
      @twitter.search(["#habits", "#neurotic"], :or)
    end

    describe "when authorization fails with HTTP 401 response" do
      before do
        mock_config
      end

      it "authorizes with OAuth and save config" do
        twitter_records, internal_records = create_rest_api_status_records({
          :from_user  => @username,
          :status     => "wassup?"
        })
        access_token = 'access token'
        user_has_authorized = states('User has authorized?').starts_as(false)
        @oauth.expects(:request_signer).twice
        @oauth.expects(:authorize).
          yields(access_token).
          then(user_has_authorized.is(true))
        http_subresource = mock
        http_subresource.expects(:get).
          raises(HttpError.new(401, 'Unauthorized')).
          when(user_has_authorized.is(false))
        http_subresource.expects(:get).
          returns(twitter_records.to_json).
          when(user_has_authorized.is(true))
        @rest_api.expects(:[]).returns(http_subresource)
        @config.expects(:[]=).with(:oauth_access, access_token)
        @config.expects(:save)
        @ui.expects(:show_tweets).with(internal_records)
        @twitter.home
      end
    end
  end

  private

  def create_rest_api_status_records(*records)
    create_twitter_and_internal_records(records, Twitter::REST_API_STATUS_PATHS) do |record|
      {
        "user"                    => { "screen_name" => record[:from_user] },
        "created_at"              => create_timestamp,
        "text"                    => record[:status],
        "in_reply_to_screen_name" => record[:to_user]
      }
    end
  end

  def create_rest_api_user_records(*records)
    create_twitter_and_internal_records(records, Twitter::REST_API_USER_PATHS) do |record|
      twitter_record = { "screen_name" => record[:from_user] }
      if record[:status]
        twitter_record.merge!({
          "status" => {
            "created_at"              => create_timestamp,
            "text"                    => record[:status],
            "in_reply_to_screen_name" => record[:to_user],
          }
        })
      end
      twitter_record
    end
  end

  def create_search_api_status_records(*records)
    twitter_records, internal_records = create_twitter_and_internal_records(
      records, Twitter::SEARCH_API_STATUS_PATHS) do |record|
      {
        "from_user"   => record[:from_user],
        "created_at"  => create_timestamp,
        "text"        => record[:status],
        "to_user"     => record[:to_user]
      }
    end
    twitter_records = { 'results' => twitter_records }
    [twitter_records, internal_records]
  end

  def create_twitter_and_internal_records(records, paths, &twitter_record_maker)
    twitter_records   = records.map(&twitter_record_maker)
    internal_records  = twitter_records.map { |rec| Tweet.new(rec, paths) rescue nil }
    [twitter_records, internal_records]
  end

  def create_timestamp
    Time.at(1).to_s
  end
end

end
