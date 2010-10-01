# coding: utf-8

require "test_helper"
require "json"

module Tweetwine

class ClientTest < TweetwineTestCase
  context "upon initialization" do
    should "use default number of statuses if not configured" do
      @twitter = Twitter.new
      assert_equal Twitter::DEFAULT_NUM_STATUSES, @twitter.num_statuses
    end

    should "use configured number of statuses if in allowed range" do
      @twitter = Twitter.new(:num_statuses => 12)
      assert_equal 12, @twitter.num_statuses
    end

    should "raise exception if configured number of status not in allowed range" do
      assert_raise(ArgumentError) { Twitter.new(:num_statuses => 0) }
    end

    should "use default page number if not configured otherwise" do
      @twitter = Twitter.new
      assert_equal Twitter::DEFAULT_PAGE_NUM, @twitter.page
    end

    should "use configured page number if in allowed range" do
      @twitter = Twitter.new(:page => 12)
      assert_equal 12, @twitter.page
    end

    should "raise exception if configured page number not in allowed range" do
      assert_raise(ArgumentError) { Twitter.new(:page => 0) }
    end
  end

  context "at runtime" do
    setup do
      mock_ui
      mock_http
      @username = "spiky"
      @rest_api = mock
      @search_api = mock
      @http.stubs(:as_resource).with("https://api.twitter.com/1").returns(@rest_api)
      @http.stubs(:as_resource).with("http://search.twitter.com").returns(@search_api)
      @twitter = Twitter.new(:username => @username)
      @rest_api_status_query_str = "count=#{Twitter::DEFAULT_NUM_STATUSES}&page=#{Twitter::DEFAULT_PAGE_NUM}"
      @search_api_query_str = "rpp=#{Twitter::DEFAULT_NUM_STATUSES}&page=#{Twitter::DEFAULT_PAGE_NUM}"
    end

    should "fetch friends' statuses (home view)" do
      twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
        {
          :from_user  => "zanzibar",
          :status     => "wassup?",
          :created_at => Time.at(1).to_s,
          :to_user    => nil
        },
        {
          :from_user  => "lulzwoo",
          :status     => "nuttin'",
          :created_at => Time.at(1).to_s,
          :to_user    => nil
        }
      )
      @rest_api.expects(:[]).
          with("statuses/home_timeline.json?#{@rest_api_status_query_str}").
          returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_record).with(internal_records[0])
      @ui.expects(:show_record).with(internal_records[1])
      @twitter.home
    end

    should "fetch mentions" do
      twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
        {
          :from_user  => "zanzibar",
          :status     => "wassup, @#{@username}?",
          :created_at => Time.at(1).to_s,
          :to_user    => @username
        },
        {
          :from_user  => "lulzwoo",
          :status     => "@#{@username}, doing nuttin'",
          :created_at => Time.at(1).to_s,
          :to_user    => @username
        }
      )
      @rest_api.expects(:[]).
          with("statuses/mentions.json?#{@rest_api_status_query_str}").
          returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_record).with(internal_records[0])
      @ui.expects(:show_record).with(internal_records[1])
      @twitter.mentions
    end

    should "fetch a specific user's statuses, when user is given as argument" do
      username = "spoonman"
      twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
        {
          :from_user  => username,
          :status     => "wassup?",
          :created_at => Time.at(1).to_s,
          :to_user    => nil
        }
      )
      @rest_api.expects(:[]).
          with("statuses/user_timeline.json?#{@rest_api_status_query_str}&screen_name=#{username}").
          returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_record).with(internal_records[0])
      @twitter.user(username)
    end

    should "fetch a specific user's statuses, with user being the authenticated user itself when given no argument" do
      twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
        {
          :from_user  => @username,
          :status     => "wassup?",
          :created_at => Time.at(1).to_s,
          :to_user    => nil
        }
      )
      @rest_api.expects(:[]).
          with("statuses/user_timeline.json?#{@rest_api_status_query_str}&screen_name=#{@username}").
          returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_record).with(internal_records[0])
      @twitter.user
    end

    context "when posting status updates" do
      should "post a status update via argument, when positive confirmation" do
        status = "wondering around"
        twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
          {
            :from_user  => @username,
            :status     => status,
            :created_at => Time.at(1).to_s,
            :to_user    => nil
          }
        )
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
        @ui.expects(:show_record).with(internal_records[0])
        @twitter.update(status)
      end

      should "post a status update via prompt, when positive confirmation" do
        status = "wondering around"
        twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
          {
            :from_user  => @username,
            :status     => status,
            :created_at => Time.at(1).to_s,
            :to_user    => nil
          }
        )
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
        @ui.expects(:show_record).with(internal_records[0])
        @twitter.update
      end

      should "cancel a status update via argument, when negative confirmation" do
        status = "wondering around"
        @rest_api.expects(:[]).never
        @ui.expects(:show_status_preview).with(status)
        @ui.expects(:confirm).with("Really send?").returns(false)
        @ui.expects(:info).with("Cancelled.")
        @ui.expects(:show_record).never
        @twitter.update(status)
      end

      should "cancel a status update via prompt, when negative confirmation" do
        status = "wondering around"
        @rest_api.expects(:[]).never
        @ui.expects(:prompt).with("Status update").returns(status)
        @ui.expects(:show_status_preview).with(status)
        @ui.expects(:confirm).with("Really send?").returns(false)
        @ui.expects(:info).with("Cancelled.")
        @ui.expects(:show_record).never
        @twitter.update
      end

      should "cancel a status update via argument, when empty status" do
        @rest_api.expects(:[]).never
        @ui.expects(:prompt).with("Status update").returns("")
        @ui.expects(:confirm).never
        @ui.expects(:info).with("Cancelled.")
        @ui.expects(:show_record).never
        @twitter.update("")
      end

      should "cancel a status update via prompt, when empty status" do
        @rest_api.expects(:[]).never
        @ui.expects(:prompt).with("Status update").returns("")
        @ui.expects(:confirm).never
        @ui.expects(:info).with("Cancelled.")
        @ui.expects(:show_record).never
        @twitter.update
      end

      should "remove excess whitespace around a status update" do
        whitespaced_status = "  oh, i was sloppy \t   "
        stripped_status = "oh, i was sloppy"
        twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
          {
            :from_user  => @username,
            :status     => stripped_status,
            :created_at => Time.at(1).to_s,
            :to_user    => nil
          }
        )
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
        @ui.expects(:show_record).with(internal_records[0])
        @twitter.update(whitespaced_status)
      end

      should "truncate a status update with too long argument and warn the user" do
        long_status = "x aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq rrr sss ttt uuu vvv www xxx yyy zzz 111 222 333 444 555 666 777 888 999 000"
        truncated_status = "x aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq rrr sss ttt uuu vvv www xxx yyy zzz 111 222 333 444 555 666 777 888 99"
        twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
          {
            :from_user  => @username,
            :status     => truncated_status,
            :created_at => Time.at(1).to_s,
            :to_user    => nil
          }
        )
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
        @ui.expects(:show_record).with(internal_records[0])
        @twitter.update(long_status)
      end

      context "with URL shortening" do
        setup do
          mock_url_shortener
          stub_config(
            :shorten_urls => {
              :service_url    => "http://shorten.it/create",
              :method         => "post",
              :url_param_name => "url",
              :xpath_selector => "//input[@id='short_url']/@value"
            }
          )
        end

        should "not shorten URLs if not configured" do
          stub_config
          status = "reading http://www.w3.org/TR/1999/REC-xpath-19991116"
          twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
            {
              :from_user  => @username,
              :status     => status,
              :created_at => Time.at(1).to_s,
              :to_user    => nil
            }
          )
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
          @ui.expects(:show_record).with(internal_records[0])
          @twitter.update(status)
        end

        should "shorten URLs, avoiding truncation with long URLs" do
          long_urls = ["http://www.google.fi/search?q=ruby+nokogiri&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a", "http://www.w3.org/TR/1999/REC-xpath-19991116"]
          long_status = long_urls.join(" and ")
          short_urls = ["http://shorten.it/2k7i8", "http://shorten.it/2k7mk"]
          shortened_status = short_urls.join(" and ")
          twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
            {
              :from_user  => @username,
              :status     => shortened_status,
              :created_at => Time.at(1).to_s,
              :to_user    => nil
            }
          )
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
          @ui.expects(:show_record).with(internal_records[0])
          @twitter.update(long_status)
        end

        should "discard obviously invalid shortened URLs, using originals instead" do
          long_urls = ["http://www.google.fi/", "http://www.w3.org/TR/1999/REC-xpath-19991116"]
          status = long_urls.join(" and ")
          short_urls = [nil, ""]
          twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
            {
              :from_user  => @username,
              :status     => status,
              :created_at => Time.at(1).to_s,
              :to_user    => nil
            }
          )
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
          @ui.expects(:show_record).with(internal_records[0])
          @twitter.update(status)
        end

        should "reuse a shortened URL for duplicate long URLs" do
          long_urls = ["http://www.w3.org/TR/1999/REC-xpath-19991116"] * 2
          long_status = long_urls.join(" and ")
          short_url = "http://shorten.it/2k7mk"
          short_status = ([short_url] * 2).join(" and ")
          twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
            {
              :from_user  => @username,
              :status     => short_status,
              :created_at => Time.at(1).to_s,
              :to_user    => nil
            }
          )
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
          @ui.expects(:show_record).with(internal_records[0])
          @twitter.update(long_status)
        end

        context "in erroneous situations" do
          setup do
            @url = "http://www.w3.org/TR/1999/REC-xpath-19991116"
            @status = "skimming through #{@url}"
            @twitter_records, @internal_records = create_test_twitter_status_records_from_rest_api(
              {
                :from_user  => @username,
                :status     => @status,
                :created_at => Time.at(1).to_s,
                :to_user    => nil
              }
            )
          end

          should "skip shortening URLs if required libraries are not found" do
            http_subresource = mock
            http_subresource.expects(:post).
                with({ :status => @status }).
                returns(@twitter_records[0].to_json)
            @rest_api.expects(:[]).
                with("statuses/update.json").
                returns(http_subresource)
            @url_shortener.expects(:shorten).with(@url).raises(LoadError, "gem not found")
            @ui.expects(:warn)
            @ui.expects(:show_status_preview).with(@status)
            @ui.expects(:confirm).with("Really send?").returns(true)
            @ui.expects(:info).with("Sent status update.\n\n")
            @ui.expects(:show_record).with(@internal_records[0])
            @twitter.update(@status)
          end

          should "skip shortening URLs upon connection error to the URL shortening service" do
            http_subresource = mock
            http_subresource.expects(:post).
                with({ :status => @status }).
                returns(@twitter_records[0].to_json)
            @rest_api.expects(:[]).
                with("statuses/update.json").
                returns(http_subresource)
            @url_shortener.expects(:shorten).with(@url).raises(HttpError, "connection error")
            @ui.expects(:warn)
            @ui.expects(:show_status_preview).with(@status)
            @ui.expects(:confirm).with("Really send?").returns(true)
            @ui.expects(:info).with("Sent status update.\n\n")
            @ui.expects(:show_record).with(@internal_records[0])
            @twitter.update(@status)
          end
        end
      end
    end

    should "fetch friends" do
      twitter_records, internal_records = create_test_twitter_user_records_from_rest_api(
        {
          :from_user  => "zanzibar",
          :status     => "wassup, @foo?",
          :created_at => Time.at(1).to_s,
          :to_user    => "foo"
        },
        {
          :from_user  => "lulzwoo",
          :status     => "@foo, doing nuttin'",
          :created_at => Time.at(1).to_s,
          :to_user    => "foo"
        }
      )
      @rest_api.expects(:[]).
          with("statuses/friends.json?#{@rest_api_status_query_str}").
          returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_record).with(internal_records[0])
      @ui.expects(:show_record).with(internal_records[1])
      @twitter.friends
    end

    should "fetch followers" do
      twitter_records, internal_records = create_test_twitter_user_records_from_rest_api(
        {
          :from_user  => "zanzibar",
          :status     => "wassup, @foo?",
          :created_at => Time.at(1).to_s,
          :to_user    => "foo"
        },
        {
          :from_user  => "lulzwoo",
          :status     => nil,
          :created_at => nil,
          :to_user    => nil
        }
      )
      @rest_api.expects(:[]).
          with("statuses/followers.json?#{@rest_api_status_query_str}").
          returns(stub(:get => twitter_records.to_json))
      @ui.expects(:show_record).with(internal_records[0])
      @ui.expects(:show_record).with(internal_records[1])
      @twitter.followers
    end

    context "when searching tweets" do
      should "raise exception if no search word is given" do
        assert_raise(ArgumentError) { @twitter.search }
      end

      [
        [nil,   "no operator"],
        [:and,  "and operator"]
      ].each do |op, desc|
        should "search tweets matching all the given words with #{desc}" do
          twitter_response, internal_records = create_test_twitter_records_from_search_api(
            {
              :from_user  => "zanzibar",
              :status     => "@foo, wassup? #greets",
              :created_at => Time.at(1).to_s,
              :to_user    => "foo"
            },
            {
              :from_user  => "spoonman",
              :status     => "@foo long time no see #greets",
              :created_at => Time.at(1).to_s,
              :to_user    => "foo"
            }
          )
          @search_api.expects(:[]).
              with("search.json?q=%23greets%20%40foo&#{@search_api_query_str}").
              returns(stub(:get => twitter_response.to_json))
          @ui.expects(:show_record).with(internal_records[0])
          @ui.expects(:show_record).with(internal_records[1])
          @twitter.search(["#greets", "@foo"], op)
        end
      end

      should "search tweets matching any of the given words with or operator" do
        twitter_response, internal_records = create_test_twitter_records_from_search_api(
          {
            :from_user  => "zanzibar",
            :status     => "spinning around the floor #habits",
            :created_at => Time.at(1).to_s,
            :to_user    => "foo"
          },
          {
            :from_user  => "spoonman",
            :status     => "drinking coffee, again #neurotic",
            :created_at => Time.at(1).to_s,
            :to_user    => "foo"
          }
        )
        @search_api.expects(:[]).
            with("search.json?q=%23habits%20OR%20%23neurotic&#{@search_api_query_str}").
            returns(stub(:get => twitter_response.to_json))
        @ui.expects(:show_record).with(internal_records[0])
        @ui.expects(:show_record).with(internal_records[1])
        @twitter.search(["#habits", "#neurotic"], :or)
      end
    end
  end
end

end
