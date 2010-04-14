# coding: utf-8

require "test_helper"
require "json"

module Tweetwine

class ClientTest < TweetwineTestCase
  context "A client instance" do
    setup do
      @io = mock()
      @http_resource = mock()
      @http_client = stub({ :as_resource => @http_resource })
      @url_shortener = mock()
      @url_shortener_block = lambda { |options| @url_shortener }
      @deps = Client::Dependencies.new @io, @http_client, @url_shortener_block
    end

    context "upon initialization" do
      should "raise exception when no authentication data is given" do
        assert_raise(ArgumentError) { Client.new(@deps, {}) }
        assert_raise(ArgumentError) { Client.new(@deps, { :password => "bar" }) }
        assert_raise(ArgumentError) { Client.new(@deps, { :username => "", :password => "bar" }) }
        assert_nothing_raised { Client.new(@deps, { :username => "foo", :password => "bar" }) }
      end

      should "use default number of statuses if not configured otherwise" do
        @client = Client.new(@deps, { :username => "foo", :password => "bar" })
        assert_equal Client::DEFAULT_NUM_STATUSES, @client.num_statuses
      end

      should "use configured number of statuses if in allowed range" do
        @client = Client.new(@deps, { :username => "foo", :password => "bar", :num_statuses => 12 })
        assert_equal 12, @client.num_statuses
      end

      should "raise an exception for configured number of statuses if not in allowed range" do
        assert_raise(ArgumentError) { Client.new(@deps, { :username => "foo", :password => "bar", :num_statuses => 0 }) }
      end

      should "use default page number if not configured otherwise" do
        @client = Client.new(@deps, { :username => "foo", :password => "bar" })
        assert_equal Client::DEFAULT_PAGE_NUM, @client.page_num
      end

      should "use configured page number if in allowed range" do
        @client = Client.new(@deps, { :username => "foo", :password => "bar", :page_num => 12 })
        assert_equal 12, @client.page_num
      end

      should "raise an exception for configured page number if not in allowed range" do
        assert_raise(ArgumentError) { Client.new(@deps, { :username => "foo", :password => "bar", :page_num => 0 }) }
      end

      should "user proper base URL and authentication information for HTTP requests" do
        http_client = mock()
        http_client.expects(:as_resource).with("https://twitter.com", :user => "foo", :password => "bar")
        deps = Client::Dependencies.new @io, http_client, @url_shortener_block
        Client.new(deps, { :username => "foo", :password => "bar" })
      end
    end

    context "at runtime" do
      setup do
        @username = "spiky"
        @password = "lullaby"
        @client = Client.new(@deps, { :username => @username, :password => @password })
        @rest_api_status_query_str = "count=#{Client::DEFAULT_NUM_STATUSES}&page=#{Client::DEFAULT_PAGE_NUM}"
        @search_api_base_url = "http://search.twitter.com/search.json"
        @search_api_query_str = "rpp=#{Client::DEFAULT_NUM_STATUSES}&page=#{Client::DEFAULT_PAGE_NUM}"
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
        @http_resource.expects(:[]) \
                      .with("statuses/home_timeline.json?#{@rest_api_status_query_str}") \
                      .returns(stub(:get => twitter_records.to_json))
        @io.expects(:show_record).with(internal_records[0])
        @io.expects(:show_record).with(internal_records[1])
        @client.home
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
        @http_resource.expects(:[]) \
                      .with("statuses/mentions.json?#{@rest_api_status_query_str}") \
                      .returns(stub(:get => twitter_records.to_json))
        @io.expects(:show_record).with(internal_records[0])
        @io.expects(:show_record).with(internal_records[1])
        @client.mentions
      end

      should "fetch a specific user's statuses, when the user identified by given argument" do
        user = "spoonman"
        twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
          {
            :from_user  => user,
            :status     => "wassup?",
            :created_at => Time.at(1).to_s,
            :to_user    => nil
          }
        )
        @http_resource.expects(:[]) \
                      .with("statuses/user_timeline/#{user}.json?#{@rest_api_status_query_str}") \
                      .returns(stub(:get => twitter_records.to_json))
        @io.expects(:show_record).with(internal_records[0])
        @client.user([user])
      end

      should "fetch a specific user's statuses, with the user being the authenticated user itself when given no argument" do
        twitter_records, internal_records = create_test_twitter_status_records_from_rest_api(
          {
            :from_user  => @username,
            :status     => "wassup?",
            :created_at => Time.at(1).to_s,
            :to_user    => nil
          }
        )
        @http_resource.expects(:[]) \
                      .with("statuses/user_timeline/#{@username}.json?#{@rest_api_status_query_str}") \
                      .returns(stub(:get => twitter_records.to_json))
        @io.expects(:show_record).with(internal_records[0])
        @client.user
      end

      context "for posting status updates" do
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
          http_subresource = mock()
          http_subresource.expects(:post) \
                          .with({ :status => status }) \
                          .returns(twitter_records[0].to_json)
          @http_resource.expects(:[]) \
                        .with("statuses/update.json") \
                        .returns(http_subresource)
          @io.expects(:confirm).with("Really send?").returns(true)
          @io.expects(:show_status_preview).with(status)
          @io.expects(:info).with("Sent status update.\n\n")
          @io.expects(:show_record).with(internal_records[0])
          @client.update([status])
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
          http_subresource = mock()
          http_subresource.expects(:post) \
                          .with({ :status => status }) \
                          .returns(twitter_records[0].to_json)
          @http_resource.expects(:[]) \
                        .with("statuses/update.json") \
                        .returns(http_subresource)
          @io.expects(:prompt).with("Status update").returns(status)
          @io.expects(:show_status_preview).with(status)
          @io.expects(:confirm).with("Really send?").returns(true)
          @io.expects(:info).with("Sent status update.\n\n")
          @io.expects(:show_record).with(internal_records[0])
          @client.update
        end

        should "cancel a status update via argument, when negative confirmation" do
          status = "wondering around"
          @http_resource.expects(:[]).never
          @io.expects(:show_status_preview).with(status)
          @io.expects(:confirm).with("Really send?").returns(false)
          @io.expects(:info).with("Cancelled.")
          @io.expects(:show_record).never
          @client.update([status])
        end

        should "cancel a status update via prompt, when negative confirmation" do
          status = "wondering around"
          @http_resource.expects(:[]).never
          @io.expects(:prompt).with("Status update").returns(status)
          @io.expects(:show_status_preview).with(status)
          @io.expects(:confirm).with("Really send?").returns(false)
          @io.expects(:info).with("Cancelled.")
          @io.expects(:show_record).never
          @client.update
        end

        should "cancel a status update via argument, when empty status" do
          @http_resource.expects(:[]).never
          @io.expects(:prompt).with("Status update").returns("")
          @io.expects(:confirm).never
          @io.expects(:info).with("Cancelled.")
          @io.expects(:show_record).never
          @client.update([""])
        end

        should "cancel a status update via prompt, when empty status" do
          @http_resource.expects(:[]).never
          @io.expects(:prompt).with("Status update").returns("")
          @io.expects(:confirm).never
          @io.expects(:info).with("Cancelled.")
          @io.expects(:show_record).never
          @client.update
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
          http_subresource = mock()
          http_subresource.expects(:post) \
                          .with({ :status => stripped_status }) \
                          .returns(twitter_records[0].to_json)
          @http_resource.expects(:[]) \
                        .with("statuses/update.json") \
                        .returns(http_subresource)
          @io.expects(:show_status_preview).with(stripped_status)
          @io.expects(:confirm).with("Really send?").returns(true)
          @io.expects(:info).with("Sent status update.\n\n")
          @io.expects(:show_record).with(internal_records[0])
          @client.update([whitespaced_status])
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
          http_subresource = mock()
          http_subresource.expects(:post) \
                          .with({ :status => truncated_status }) \
                          .returns(twitter_records[0].to_json)
          @http_resource.expects(:[]) \
                        .with("statuses/update.json") \
                        .returns(http_subresource)
          @io.expects(:warn).with("Status will be truncated.")
          @io.expects(:show_status_preview).with(truncated_status)
          @io.expects(:confirm).with("Really send?").returns(true)
          @io.expects(:info).with("Sent status update.\n\n")
          @io.expects(:show_record).with(internal_records[0])
          @client.update([long_status])
        end

        context "with URL shortening enabled" do
          setup do
            @client = Client.new(@deps, {
              :username => @username,
              :password => @password,
              :shorten_urls => {
                :enable         => true,
                :service_url    => "http://shorten.it/create",
                :method         => "post",
                :url_param_name => "url",
                :xpath_selector => "//input[@id='short_url']/@value"
              }
            })
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
            http_subresource = mock()
            http_subresource.expects(:post) \
                            .with({ :status => shortened_status }) \
                            .returns(twitter_records[0].to_json)
            @http_resource.expects(:[]) \
                          .with("statuses/update.json") \
                          .returns(http_subresource)
            @url_shortener.expects(:shorten).with(long_urls.first).returns(short_urls.first)
            @url_shortener.expects(:shorten).with(long_urls.last).returns(short_urls.last)
            @io.expects(:show_status_preview).with(shortened_status)
            @io.expects(:confirm).with("Really send?").returns(true)
            @io.expects(:info).with("Sent status update.\n\n")
            @io.expects(:show_record).with(internal_records[0])
            @client.update([long_status])
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
            http_subresource = mock()
            http_subresource.expects(:post) \
                            .with({ :status => status }) \
                            .returns(twitter_records[0].to_json)
            @http_resource.expects(:[]) \
                          .with("statuses/update.json") \
                          .returns(http_subresource)
            @url_shortener.expects(:shorten).with(long_urls.first).returns(short_urls.first)
            @url_shortener.expects(:shorten).with(long_urls.last).returns(short_urls.last)
            @io.expects(:show_status_preview).with(status)
            @io.expects(:confirm).with("Really send?").returns(true)
            @io.expects(:info).with("Sent status update.\n\n")
            @io.expects(:show_record).with(internal_records[0])
            @client.update([status])
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
            http_subresource = mock()
            http_subresource.expects(:post) \
                            .with({ :status => short_status }) \
                            .returns(twitter_records[0].to_json)
            @http_resource.expects(:[]) \
                          .with("statuses/update.json") \
                          .returns(http_subresource)
            @url_shortener.expects(:shorten).with(long_urls.first).returns(short_url)
            @io.expects(:show_status_preview).with(short_status)
            @io.expects(:confirm).with("Really send?").returns(true)
            @io.expects(:info).with("Sent status update.\n\n")
            @io.expects(:show_record).with(internal_records[0])
            @client.update([long_status])
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
              http_subresource = mock()
              http_subresource.expects(:post) \
                              .with({ :status => @status }) \
                              .returns(@twitter_records[0].to_json)
              @http_resource.expects(:[]) \
                            .with("statuses/update.json") \
                            .returns(http_subresource)
              @url_shortener.expects(:shorten).with(@url).raises(LoadError, "gem not found")
              @io.expects(:warn)
              @io.expects(:show_status_preview).with(@status)
              @io.expects(:confirm).with("Really send?").returns(true)
              @io.expects(:info).with("Sent status update.\n\n")
              @io.expects(:show_record).with(@internal_records[0])
              @client.update([@status])
            end

            should "skip shortening URLs upon connection error to the URL shortening service" do
              http_subresource = mock()
              http_subresource.expects(:post) \
                              .with({ :status => @status }) \
                              .returns(@twitter_records[0].to_json)
              @http_resource.expects(:[]) \
                            .with("statuses/update.json") \
                            .returns(http_subresource)
              @url_shortener.expects(:shorten).with(@url).raises(HttpError, "connection error")
              @io.expects(:warn)
              @io.expects(:show_status_preview).with(@status)
              @io.expects(:confirm).with("Really send?").returns(true)
              @io.expects(:info).with("Sent status update.\n\n")
              @io.expects(:show_record).with(@internal_records[0])
              @client.update([@status])
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
        @http_resource.expects(:[]) \
                      .with("statuses/friends/#{@username}.json") \
                      .returns(stub(:get => twitter_records.to_json))
        @io.expects(:show_record).with(internal_records[0])
        @io.expects(:show_record).with(internal_records[1])
        @client.friends
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
        @http_resource.expects(:[]) \
                      .with("statuses/followers/#{@username}.json") \
                      .returns(stub(:get => twitter_records.to_json))
        @io.expects(:show_record).with(internal_records[0])
        @io.expects(:show_record).with(internal_records[1])
        @client.followers
      end

      context "for searching tweets" do
        should "raise exception if no search word is given" do
          assert_raise(ArgumentError) { @client.search() }
        end

        should "allow searching for tweets that match all the given words" do
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
          @http_client.expects(:get) \
                      .with("#{@search_api_base_url}?q=%23greets%20%40foo&#{@search_api_query_str}") \
                      .returns(twitter_response.to_json)
          @io.expects(:show_record).with(internal_records[0])
          @io.expects(:show_record).with(internal_records[1])
          @client.search(["#greets", "@foo"])
        end

        should "allow searching for tweets that match any of the given words" do
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
          @http_client.expects(:get) \
                      .with("#{@search_api_base_url}?q=%23habits%20OR%20%23neurotic&#{@search_api_query_str}") \
                      .returns(twitter_response.to_json)
          @io.expects(:show_record).with(internal_records[0])
          @io.expects(:show_record).with(internal_records[1])
          @client.search(["#habits", "#neurotic"], {:bin_op => :or})
        end
      end
    end
  end
end

end
