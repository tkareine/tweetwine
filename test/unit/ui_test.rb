# coding: utf-8

require 'unit/helper'
require 'unit/tweet_helper'

module Tweetwine::Test

class UITest < UnitTestCase
  include TweetHelper

  context "a UI instance" do
    setup do
      @in  = mock
      @out = mock
      @err = mock
      @ui  = UI.new({ :in => @in, :out => @out, :err => @err })
    end

    should "output prompt and return input as trimmed" do
      @out.expects(:print).with("The answer: ")
      @in.expects(:gets).returns("  42 ")
      assert_equal "42", @ui.prompt("The answer")
    end

    should "output info message" do
      @out.expects(:puts).with("foo")
      @ui.info("foo")
    end

    should "output info message in process style when given a block" do
      inform = sequence('inform')
      @out.expects(:print).with("processing...").in_sequence(inform)
      @out.expects(:puts).with(" done.").in_sequence(inform)
      @ui.info("processing...") { true }
    end

    should "output empty line as info message" do
      @out.expects(:puts).with("\n")
      @ui.info
    end

    should "output warning message" do
      @out.expects(:puts).with("Warning: monkey patching ahead")
      @ui.warn("monkey patching ahead")
    end

    should "output error message" do
      @err.expects(:puts).with("ERROR: Invalid monkey patch")
      @ui.error("Invalid monkey patch")
    end

    should "confirm action, with positive answer" do
      @out.expects(:print).with("Fire nukes? [yN] ")
      @in.expects(:gets).returns("y")
      assert_equal true, @ui.confirm("Fire nukes?")
    end

    should "confirm action, with negative answer" do
      @out.expects(:print).with("Fire nukes? [yN] ")
      @in.expects(:gets).returns("n")
      assert_equal false, @ui.confirm("Fire nukes?")
    end

    should "confirm action, with default answer" do
      @out.expects(:print).with("Fire nukes? [yN] ")
      @in.expects(:gets).returns("")
      assert_equal false, @ui.confirm("Fire nukes?")
    end

    context "with colorization disabled" do
      setup do
        @ui = UI.new({:in => @in, :out => @out, :colors => false })
      end

      should "output tweet with just user info" do
        from_user = "fooman"
        tweet = create_tweet(:from_user => from_user)
        @out.expects(:puts).with(<<-END
#{from_user}

        END
        )
        @ui.show_tweet(tweet)
      end

      should "output regular tweet" do
        from_user = "fooman"
        status = "Hi, @barman! Lulz woo! #hellos"
        time = 2
        tweet = create_tweet(
          :from_user  => from_user,
          :status     => status,
          :created_at => create_timestamp(time)
        )
        @out.expects(:puts).with(<<-END
#{from_user}, #{time} sec ago:
#{status}

        END
        )
        show_tweet_at_default_time(tweet)
      end

      should "output replying tweet" do
        from_user = "barman"
        to_user = "fooman"
        status = "Hi, @#{to_user}! How are you doing?"
        tweet = create_tweet(
          :from_user  => from_user,
          :status     => status,
          :to_user    => to_user
        )
        @out.expects(:puts).with(<<-END
#{from_user}, in reply to #{to_user}, 0 sec ago:
#{status}

        END
        )
        show_tweet_at_default_time(tweet)
      end

      should "output regular retweet" do
        from_user = "barman"
        rt_user = "fooman"
        status = "status worth retweeting"
        tweet = create_tweet(
          :from_user  => from_user,
          :status     => status,
          :rt_user    => rt_user
        )
        @out.expects(:puts).with(<<-END
#{rt_user} RT #{from_user}, 0 sec ago:
#{status}

        END
        )
        show_tweet_at_default_time(tweet)
      end

      should "output replying retweet" do
        from_user = "barman"
        to_user = "jackman"
        rt_user = "fooman"
        status = "@#{to_user}, reply worth retweeting"
        tweet = create_tweet(
          :from_user  => from_user,
          :to_user    => to_user,
          :status     => status,
          :rt_user    => rt_user
        )
        @out.expects(:puts).with(<<-END
#{rt_user} RT #{from_user}, in reply to #{to_user}, 0 sec ago:
#{status}

        END
        )
        show_tweet_at_default_time(tweet)
      end

      should "unescape HTML in a status" do
        from_user = "fooman"
        escaped_status = "apple &gt; orange &amp; grapefruit &lt; banana"
        unescaped_status = "apple > orange & grapefruit < banana"
        tweet = create_tweet(
          :from_user  => from_user,
          :status     => escaped_status
        )
        @out.expects(:puts).with(<<-END
#{from_user}, 0 sec ago:
#{unescaped_status}

        END
        )
        show_tweet_at_default_time(tweet)
      end

      should "output a preview of a status" do
        status = "@nick, check http://bit.ly/18rU_Vx"
        @out.expects(:puts).with(<<-END

#{status}

        END
        )
        @ui.show_status_preview(status)
      end
    end

    context "with colorization enabled" do
      setup do
        @ui = UI.new({:in => @in, :out => @out, :colors => true})
      end

      should "output tweet with just user info" do
        from_user = "fooman"
        tweet = create_tweet(:from_user => from_user)
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m

        END
        )
        @ui.show_tweet(tweet)
      end

      should "output regular tweet" do
        from_user = "fooman"
        status = "Wondering about the meaning of life."
        tweet = create_tweet(
          :from_user  => from_user,
          :status     => status
        )
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 0 sec ago:
#{status}

        END
        )
        show_tweet_at_default_time(tweet)
      end

      should "output replying tweet" do
        from_user = "barman"
        to_user = "fooman"
        tweet = create_tweet(
          :from_user  => from_user,
          :status     => "@#{to_user}! How are you doing?",
          :to_user    => to_user
        )
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, in reply to \e[32m#{to_user}\e[0m, 0 sec ago:
\e[33m@#{to_user}\e[0m! How are you doing?

        END
        )
        show_tweet_at_default_time(tweet)
      end

      should "output regular retweet" do
        from_user = "barman"
        rt_user = "fooman"
        status = "status worth retweeting"
        tweet = create_tweet(
          :from_user  => from_user,
          :status     => status,
          :rt_user    => rt_user
        )
        @out.expects(:puts).with(<<-END
\e[32m#{rt_user}\e[0m RT \e[32m#{from_user}\e[0m, 0 sec ago:
#{status}

        END
        )
        show_tweet_at_default_time(tweet)
      end

      should "output replying retweet" do
        from_user = "barman"
        to_user = "jackman"
        rt_user = "fooman"
        tweet = create_tweet(
          :from_user  => from_user,
          :to_user    => to_user,
          :status     => "@#{to_user}, reply worth retweeting",
          :rt_user    => rt_user
        )
        @out.expects(:puts).with(<<-END
\e[32m#{rt_user}\e[0m RT \e[32m#{from_user}\e[0m, in reply to \e[32m#{to_user}\e[0m, 0 sec ago:
\e[33m@#{to_user}\e[0m, reply worth retweeting

        END
        )
        show_tweet_at_default_time(tweet)
      end

      should "output a preview of a status" do
        status = "@nick, check http://bit.ly/18rU_Vx"
        @out.expects(:puts).with(<<-END

\e[33m@nick\e[0m, check \e[36mhttp://bit.ly/18rU_Vx\e[0m

        END
        )
        @ui.show_status_preview(status)
      end

      should "highlight hashtags in a status" do
        from_user = "barman"
        hashtags = %w{#slang #beignHappy}
        tweet = create_tweet(
          :from_user  => from_user,
          :status     => "Lulz, so happy! #{hashtags[0]} #{hashtags[1]}"
        )
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 0 sec ago:
Lulz, so happy! \e[35m#{hashtags[0]}\e[0m \e[35m#{hashtags[1]}\e[0m

        END
        )
        show_tweet_at_default_time(tweet)
      end

      %w{http://is.gd/1qLk3 http://is.gd/1qLk3?id=foo}.each do |url|
        should "highlight HTTP and HTTPS URLs in a status, given #{url}" do
          from_user = "barman"
          tweet = create_tweet(
            :from_user  => from_user,
            :status     => "New Rails³ - #{url}"
          )
          @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 0 sec ago:
New Rails³ - \e[36m#{url}\e[0m

          END
          )
          show_tweet_at_default_time(tweet)
        end
      end

      [
        %w{http://is.gd/1qLk3 http://is.gd/1qLk3},
        %w{http://is.gd/1qLk3 http://is.gd/1q}
      ].each do |(first_url, second_url)|
        should "highlight HTTP and HTTPS URLs in a status, given #{first_url} and #{second_url}" do
          from_user = "barman"
          tweet = create_tweet(
            :from_user  => from_user,
            :status     => "Links: #{first_url} and #{second_url} np"
          )
          @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 0 sec ago:
Links: \e[36m#{first_url}\e[0m and \e[36m#{second_url}\e[0m np

          END
          )
          show_tweet_at_default_time(tweet)
        end
      end

      should "highlight usernames in a status" do
        from_user = "barman"
        users = %w{@fooman @barbaz @spoonman}
        tweet = create_tweet(
          :from_user  => from_user,
          :status     => "I salute you #{users[0]}, #{users[1]}, and #{users[2]}!"
        )
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 0 sec ago:
I salute you \e[33m#{users[0]}\e[0m, \e[33m#{users[1]}\e[0m, and \e[33m#{users[2]}\e[0m!

        END
        )
        show_tweet_at_default_time(tweet)
      end

      should "not highlight email addresses as usernames in a status" do
        from_user = "barman"
        users = %w{@fooman @barbaz}
        email = "barbaz@foo.net"
        tweet = create_tweet(
          :from_user  => from_user,
          :status     => "Hi, #{users[0]}! You should notify #{users[1]}, #{email}"
        )
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 0 sec ago:
Hi, \e[33m#{users[0]}\e[0m! You should notify \e[33m#{users[1]}\e[0m, #{email}

        END
        )
        show_tweet_at_default_time(tweet)
      end
    end

    context "for outputting a collection of tweets" do
      setup do
        users_and_times = [
          ['first',  11],
          ['second', 12],
          ['third',  13]
        ]
        statuses = users_and_times.map { |(user, _)| "Hi, I'm #{user}." }
        users_and_statuses = users_and_times.zip(statuses)
        @outputs = Hash[users_and_statuses.map { |(user, time), status|
          output = <<-END
#{user}, #{time} sec ago:
#{status}

          END
          [user.to_sym, output]
        }]
        @tweets = users_and_statuses.map { |(user, time), status| create_tweet(
          :from_user  => user,
          :status     => status,
          :created_at => create_timestamp(time)
        )}
      end

      should "output tweets in normal order" do
        @ui = UI.new({ :out => @out, :show_reverse => false })
        [:first, :second, :third].each do |user|
          @out.expects(:puts).with(@outputs[user])
        end
        show_tweets_at_default_time(@tweets)
      end

      should "output tweets in reverse order" do
        @ui = UI.new({ :out => @out, :show_reverse => true })
        [:third, :second, :first].each do |user|
          @out.expects(:puts).with(@outputs[user])
        end
        show_tweets_at_default_time(@tweets)
      end
    end
  end

  context "username regex" do
    [
      ['@nick',     'normal'],
      ['@nick_man', 'underscore separated'],
      [' @nick',    'beginning with space']
    ].each do |(nick, desc)|
      should "match proper username reference, case #{desc}" do
        assert_full_match UI::USERNAME_REGEX, nick
      end
    end

    [
      ['@',         'just prefix'],
      ['nick',      'just body'],
      ['-@nick',    'beginning with dash'],
      ['@nick-man', 'dash separated'],
      ['@nick ',    'ending with space'],
      [' @nick ',   'surrounded with space'],
      ['man @nick', 'space separated'],
      ['man@nick',  'prefix in between']
    ].each do |(no_nick, desc)|
      should "not match an inproper username reference, case #{desc}" do
        assert_no_full_match UI::USERNAME_REGEX, no_nick
      end
    end
  end

  context "hashtag regex" do
    [
      ['#mayhem',         'normal'],
      ['#friday_mayhem',  'underscore separated'],
      ['#friday-mayhem',  'dash separated']
    ].each do |(hashtag, desc)|
      should "match a proper hashtag reference, case #{desc}" do
        assert_full_match UI::HASHTAG_REGEX, hashtag
      end
    end

    [
      ['#',         'just prefix'],
      ['mayhem',    'just body'],
      [' #mayhem',  'beginning with space'],
      ['#mayhem ',  'ending with space'],
      [' #mayhem ', 'surrounded with space']
    ].each do |(no_hashtag, desc)|
      should "not match an inproper hashtag reference, case #{desc}" do
        assert_no_full_match UI::HASHTAG_REGEX, no_hashtag
      end
    end
  end

  private

  def show_tweet_at_default_time(tweet)
    at_default_time { @ui.show_tweet(tweet) }
  end

  def show_tweets_at_default_time(tweets)
    at_default_time { @ui.show_tweets(tweets) }
  end
end

end
