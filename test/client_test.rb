require "test_helper"
require "json"

Mocha::Configuration.allow(:stubbing_non_existent_method)

module Tweetwine

class ClientTest < Test::Unit::TestCase
  context "A client instance" do
    setup do
      @io = mock()
      @rest_client = mock()
      @url_shortener = mock()
      url_shortener = lambda { |options| @url_shortener }
      @deps = {
        :io             => @io,
        :rest_client    => @rest_client,
        :url_shortener  => url_shortener
      }
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
    end

    context "at runtime" do
      setup do
        @username = "spiky"
        @password = "lullaby"
        @client = Client.new(@deps, { :username => @username, :password => @password })
        @base_url = "https://#{@username}:#{@password}@twitter.com"
        @statuses_query_params = "count=#{Client::DEFAULT_NUM_STATUSES}&page=#{Client::DEFAULT_PAGE_NUM}"
        @users_query_params = "page=#{Client::DEFAULT_PAGE_NUM}"
      end

      should "fetch friends' statuses (home view)" do
        status_records, gen_records = create_test_statuses(
          {
            :user => "zanzibar",
            :status => {
              :created_at   => Time.at(1).to_s,
              :text         => "wassup?",
              :in_reply_to  => nil
            }
          },
          {
            :user => "lulzwoo",
            :status => {
              :created_at   => Time.at(1).to_s,
              :text         => "nuttin'",
              :in_reply_to  => nil
            }
          }
        )
        @rest_client.expects(:get) \
            .with("#{@base_url}/statuses/friends_timeline.json?#{@statuses_query_params}") \
            .returns(status_records.to_json)
        @io.expects(:show_record).with(gen_records[0])
        @io.expects(:show_record).with(gen_records[1])
        @client.home
      end

      should "fetch mentions" do
        status_records, gen_records = create_test_statuses(
          {
            :user => "zanzibar",
            :status => {
              :created_at   => Time.at(1).to_s,
              :text         => "wassup, @#{@username}?",
              :in_reply_to  => @username
            }
          },
          {
            :user => "lulzwoo",
            :status => {
              :created_at   => Time.at(1).to_s,
              :text         => "@#{@username}, doing nuttin'",
              :in_reply_to  => @username
            }
          }
        )
        @rest_client.expects(:get) \
            .with("#{@base_url}/statuses/mentions.json?#{@statuses_query_params}") \
            .returns(status_records.to_json)
        @io.expects(:show_record).with(gen_records[0])
        @io.expects(:show_record).with(gen_records[1])
        @client.mentions
      end

      should "fetch a specific user's statuses, when the user identified by given argument" do
        user = "spoonman"
        status_records, gen_records = create_test_statuses(
          {
            :user => user,
            :status => {
              :created_at   => Time.at(1).to_s,
              :text         => "wassup?",
              :in_reply_to  => nil
            }
          }
        )
        @rest_client.expects(:get) \
            .with("#{@base_url}/statuses/user_timeline/#{user}.json?#{@statuses_query_params}") \
            .returns(status_records.to_json)
        @io.expects(:show_record).with(gen_records[0])
        @client.user(user)
      end

      should "fetch a specific user's statuses, with the user being the authenticated user itself when given no argument" do
        status_records, gen_records = create_test_statuses(
          {
            :user => @username,
            :status => {
              :created_at   => Time.at(1).to_s,
              :text         => "wassup?",
              :in_reply_to  => nil
            }
          }
        )
        @rest_client.expects(:get) \
            .with("#{@base_url}/statuses/user_timeline/#{@username}.json?#{@statuses_query_params}") \
            .returns(status_records.to_json)
        @io.expects(:show_record).with(gen_records[0])
        @client.user
      end

      context "for posting status updates" do
        should "post a status update via argument, when positive confirmation" do
          status = "wondering around"
          status_records, gen_records = create_test_statuses(
            {
              :user => @username,
              :status => {
                :created_at   => Time.at(1).to_s,
                :text         => status,
                :in_reply_to  => nil
              }
            }
          )
          @rest_client.expects(:post) \
              .with("#{@base_url}/statuses/update.json", {:status => status}) \
              .returns(status_records[0].to_json)
          @io.expects(:confirm).with("Really send?").returns(true)
          @io.expects(:show_status_preview).with(status)
          @io.expects(:info).with("Sent status update.\n\n")
          @io.expects(:show_record).with(gen_records[0])
          @client.update(status)
        end

        should "post a status update via prompt, when positive confirmation" do
          status = "wondering around"
          status_records, gen_records = create_test_statuses(
            { :user => @username,
              :status => {
                :created_at   => Time.at(1).to_s,
                :text         => status,
                :in_reply_to  => nil
              }
            }
          )
          @rest_client.expects(:post) \
              .with("#{@base_url}/statuses/update.json", {:status => status}) \
              .returns(status_records[0].to_json)
          @io.expects(:prompt).with("Status update").returns(status)
          @io.expects(:show_status_preview).with(status)
          @io.expects(:confirm).with("Really send?").returns(true)
          @io.expects(:info).with("Sent status update.\n\n")
          @io.expects(:show_record).with(gen_records[0])
          @client.update
        end

        should "cancel a status update via argument, when negative confirmation" do
          status = "wondering around"
          @rest_client.expects(:post).never
          @io.expects(:show_status_preview).with(status)
          @io.expects(:confirm).with("Really send?").returns(false)
          @io.expects(:info).with("Cancelled.")
          @io.expects(:show_record).never
          @client.update(status)
        end

        should "cancel a status update via prompt, when negative confirmation" do
          status = "wondering around"
          @rest_client.expects(:post).never
          @io.expects(:prompt).with("Status update").returns(status)
          @io.expects(:show_status_preview).with(status)
          @io.expects(:confirm).with("Really send?").returns(false)
          @io.expects(:info).with("Cancelled.")
          @io.expects(:show_record).never
          @client.update
        end

        should "cancel a status update via argument, when empty status" do
          @rest_client.expects(:post).never
          @io.expects(:confirm).never
          @io.expects(:info).with("Cancelled.")
          @io.expects(:show_record).never
          @client.update("")
        end

        should "cancel a status update via prompt, when empty status" do
          @rest_client.expects(:post).never
          @io.expects(:prompt).with("Status update").returns("")
          @io.expects(:confirm).never
          @io.expects(:info).with("Cancelled.")
          @io.expects(:show_record).never
          @client.update
        end

        should "remove excess whitespace around a status update" do
          whitespaced_status = "  oh, i was sloppy \t   "
          stripped_status = "oh, i was sloppy"
          status_records, gen_records = create_test_statuses(
            { :user => @username,
              :status => {
                :created_at   => Time.at(1).to_s,
                :text         => stripped_status,
                :in_reply_to  => nil
              }
            }
          )
          @rest_client.expects(:post) \
              .with("#{@base_url}/statuses/update.json", {:status => stripped_status}) \
              .returns(status_records[0].to_json)
          @io.expects(:show_status_preview).with(stripped_status)
          @io.expects(:confirm).with("Really send?").returns(true)
          @io.expects(:info).with("Sent status update.\n\n")
          @io.expects(:show_record).with(gen_records[0])
          @client.update(whitespaced_status)
        end

        should "truncate a status update with too long argument and warn the user" do
          long_status = "x aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq rrr sss ttt uuu vvv www xxx yyy zzz 111 222 333 444 555 666 777 888 999 000"
          truncated_status = "x aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq rrr sss ttt uuu vvv www xxx yyy zzz 111 222 333 444 555 666 777 888 99"
          status_records, gen_records = create_test_statuses(
            { :user => @username,
              :status => {
                :created_at   => Time.at(1).to_s,
                :text         => truncated_status,
                :in_reply_to  => nil
              }
            }
          )
          @rest_client.expects(:post) \
              .with("#{@base_url}/statuses/update.json", {:status => truncated_status}) \
              .returns(status_records[0].to_json)
          @io.expects(:warn).with("Status will be truncated.")
          @io.expects(:show_status_preview).with(truncated_status)
          @io.expects(:confirm).with("Really send?").returns(true)
          @io.expects(:info).with("Sent status update.\n\n")
          @io.expects(:show_record).with(gen_records[0])
          @client.update(long_status)
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
            status_records, gen_records = create_test_statuses(
              { :user => @username,
                :status => {
                  :created_at   => Time.at(1).to_s,
                  :text         => shortened_status,
                  :in_reply_to  => nil
                }
              }
            )
            @rest_client.expects(:post) \
                .with("#{@base_url}/statuses/update.json", {:status => shortened_status}) \
                .returns(status_records[0].to_json)
            @url_shortener.expects(:shorten).with(long_urls.first).returns(short_urls.first)
            @url_shortener.expects(:shorten).with(long_urls.last).returns(short_urls.last)
            @io.expects(:show_status_preview).with(shortened_status)
            @io.expects(:confirm).with("Really send?").returns(true)
            @io.expects(:info).with("Sent status update.\n\n")
            @io.expects(:show_record).with(gen_records[0])
            @client.update(long_status)
          end

          should "discard obviously invalid shortened URLs, using originals instead" do
            long_urls = ["http://www.google.fi/", "http://www.w3.org/TR/1999/REC-xpath-19991116"]
            status = long_urls.join(" and ")
            short_urls = [nil, ""]
            status_records, gen_records = create_test_statuses(
              { :user => @username,
                :status => {
                  :created_at   => Time.at(1).to_s,
                  :text         => status,
                  :in_reply_to  => nil
                }
              }
            )
            @rest_client.expects(:post) \
                .with("#{@base_url}/statuses/update.json", {:status => status}) \
                .returns(status_records[0].to_json)
            @url_shortener.expects(:shorten).with(long_urls.first).returns(short_urls.first)
            @url_shortener.expects(:shorten).with(long_urls.last).returns(short_urls.last)
            @io.expects(:show_status_preview).with(status)
            @io.expects(:confirm).with("Really send?").returns(true)
            @io.expects(:info).with("Sent status update.\n\n")
            @io.expects(:show_record).with(gen_records[0])
            @client.update(status)
          end

          should "reuse a shortened URL for duplicate long URLs" do
            long_urls = ["http://www.w3.org/TR/1999/REC-xpath-19991116"] * 2
            long_status = long_urls.join(" and ")
            short_url = "http://shorten.it/2k7mk"
            short_status = ([short_url] * 2).join(" and ")
            status_records, gen_records = create_test_statuses(
              { :user => @username,
                :status => {
                  :created_at   => Time.at(1).to_s,
                  :text         => short_status,
                  :in_reply_to  => nil
                }
              }
            )
            @rest_client.expects(:post) \
                .with("#{@base_url}/statuses/update.json", {:status => short_status}) \
                .returns(status_records[0].to_json)
            @url_shortener.expects(:shorten).with(long_urls.first).returns(short_url)
            @io.expects(:show_status_preview).with(short_status)
            @io.expects(:confirm).with("Really send?").returns(true)
            @io.expects(:info).with("Sent status update.\n\n")
            @io.expects(:show_record).with(gen_records[0])
            @client.update(long_status)
          end

          context "in erroneous situations" do
            setup do
              @url = "http://www.w3.org/TR/1999/REC-xpath-19991116"
              @status = "skimming through #{@url}"
              @status_records, @gen_records = create_test_statuses(
                { :user => @username,
                  :status => {
                    :created_at   => Time.at(1).to_s,
                    :text         => @status,
                    :in_reply_to  => nil
                  }
                }
              )
            end

            should "skip shortening URLs if required libraries are not found" do
              @rest_client.expects(:post) \
                  .with("#{@base_url}/statuses/update.json", {:status => @status}) \
                  .returns(@status_records[0].to_json)
              @url_shortener.expects(:shorten).with(@url).raises(LoadError, "gem not found")
              @io.expects(:warn)
              @io.expects(:show_status_preview).with(@status)
              @io.expects(:confirm).with("Really send?").returns(true)
              @io.expects(:info).with("Sent status update.\n\n")
              @io.expects(:show_record).with(@gen_records[0])
              @client.update(@status)
            end

            should "skip shortening URLs upon connection error to the URL shortening service" do
              @rest_client.expects(:post) \
                  .with("#{@base_url}/statuses/update.json", {:status => @status}) \
                  .returns(@status_records[0].to_json)
              @url_shortener.expects(:shorten).with(@url).raises(ClientError, "connection error")
              @io.expects(:warn)
              @io.expects(:show_status_preview).with(@status)
              @io.expects(:confirm).with("Really send?").returns(true)
              @io.expects(:info).with("Sent status update.\n\n")
              @io.expects(:show_record).with(@gen_records[0])
              @client.update(@status)
            end
          end
        end
      end

      should "fetch friends" do
        user_records, gen_records = create_test_users(
          {
            :user => "zanzibar",
            :status => {
              :created_at   => Time.at(1).to_s,
              :text         => "wassup, @foo?",
              :in_reply_to  => "foo"
            }
          },
          {
            :user => "lulzwoo",
            :status => {
              :created_at   => Time.at(1).to_s,
              :text         => "@foo, doing nuttin'",
              :in_reply_to  => "foo"
            }
          }
        )
        @rest_client.expects(:get) \
            .with("#{@base_url}/statuses/friends/#{@username}.json?#{@users_query_params}") \
            .returns(user_records.to_json)
        @io.expects(:show_record).with(gen_records[0])
        @io.expects(:show_record).with(gen_records[1])
        @client.friends
      end

      should "fetch followers" do
        user_records, gen_records = create_test_users(
          {
            :user => "zanzibar",
            :status => {
              :created_at   => Time.at(1).to_s,
              :text         => "wassup, @foo?",
              :in_reply_to  => "foo"
            }
          },
          {
            :user => "lulzwoo"
          }
        )
        @rest_client.expects(:get) \
            .with("#{@base_url}/statuses/followers/#{@username}.json?#{@users_query_params}") \
            .returns(user_records.to_json)
        @io.expects(:show_record).with(gen_records[0])
        @io.expects(:show_record).with(gen_records[1])
        @client.followers
      end
    end
  end
end

end
