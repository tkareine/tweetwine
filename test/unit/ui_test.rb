# coding: utf-8

require "unit_helper"

module Tweetwine::Test

class UITest < UnitTestCase
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

      should "output a record as user info when no status is given" do
        from_user = "fooman"
        record = { :from_user => from_user }
        @out.expects(:puts).with(<<-END
#{from_user}

        END
        )
        @ui.show_record(record)
      end

      should "output a record as status info when status is given, without in-reply info" do
        from_user = "fooman"
        status = "Hi, @barman! Lulz woo! #hellos"
        record = {
          :from_user  => from_user,
          :status     => status,
          :created_at => Time.at(1),
          :to_user    => nil
        }
        Support.expects(:humanize_time_diff).returns([2, "secs"])
        @out.expects(:puts).with(<<-END
#{from_user}, 2 secs ago:
#{status}

        END
        )
        @ui.show_record(record)
      end

      should "output a record as status info when status is given, with in-reply info" do
        from_user = "barman"
        to_user = "fooman"
        status = "Hi, @fooman! How are you doing?"
        record = {
          :from_user  => from_user,
          :status     => status,
          :created_at => Time.at(1),
          :to_user    => to_user
        }
        Support.expects(:humanize_time_diff).returns([2, "secs"])
        @out.expects(:puts).with(<<-END
#{from_user}, in reply to #{to_user}, 2 secs ago:
#{status}

        END
        )
        @ui.show_record(record)
      end


      should "unescape HTML in a status" do
        from_user = "fooman"
        escaped_status = "apple &gt; orange &amp; grapefruit &lt; banana"
        unescaped_status = "apple > orange & grapefruit < banana"
        record = {
          :from_user  => from_user,
          :status     => escaped_status,
          :created_at => Time.at(1),
          :to_user    => nil
        }
        Support.expects(:humanize_time_diff).returns([2, "secs"])
        @out.expects(:puts).with(<<-END
#{from_user}, 2 secs ago:
#{unescaped_status}

        END
        )
        @ui.show_record(record)
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

      should "output a record as user info when no status is given" do
        from_user = "fooman"
        record = { :from_user => from_user }
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m

        END
        )
        @ui.show_record(record)
      end

      should "output a record as status info when status is given, without in-reply info" do
        from_user = "fooman"
        status = "Wondering about the meaning of life."
        record = {
          :from_user  => from_user,
          :status     => status,
          :created_at => Time.at(1),
          :to_user    => nil
        }
        Support.expects(:humanize_time_diff).returns([2, "secs"])
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
#{status}

        END
        )
        @ui.show_record(record)
      end

      should "output a record as status info when status is given, with in-reply info" do
        from_user = "barman"
        to_user = "fooman"
        record = {
          :from_user  => from_user,
          :status     => "@#{to_user}! How are you doing?",
          :created_at => Time.at(1),
          :to_user    => to_user
        }
        Support.expects(:humanize_time_diff).returns([2, "secs"])
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, in reply to \e[32m#{to_user}\e[0m, 2 secs ago:
\e[33m@#{to_user}\e[0m! How are you doing?

        END
        )
        @ui.show_record(record)
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
        record = {
          :from_user  => from_user,
          :status     => "Lulz, so happy! #{hashtags[0]} #{hashtags[1]}",
          :created_at => Time.at(1),
          :to_user    => nil
        }
        Support.expects(:humanize_time_diff).returns([2, "secs"])
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
Lulz, so happy! \e[35m#{hashtags[0]}\e[0m \e[35m#{hashtags[1]}\e[0m

        END
        )
        @ui.show_record(record)
      end

      %w{http://is.gd/1qLk3 http://is.gd/1qLk3?id=foo}.each do |url|
        should "highlight HTTP and HTTPS URLs in a status, given #{url}" do
          from_user = "barman"
          record = {
            :from_user  => from_user,
            :status     => "New Rails³ - #{url}",
            :created_at => Time.at(1),
            :to_user    => nil
          }
          Support.expects(:humanize_time_diff).returns([2, "secs"])
          @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
New Rails³ - \e[36m#{url}\e[0m

          END
          )
          @ui.show_record(record)
        end
      end

      [
        %w{http://is.gd/1qLk3 http://is.gd/1qLk3},
        %w{http://is.gd/1qLk3 http://is.gd/1q}
      ].each do |(first_url, second_url)|
        should "highlight HTTP and HTTPS URLs in a status, given #{first_url} and #{second_url}" do
          from_user = "barman"
          record = {
            :from_user  => from_user,
            :status     => "Links: #{first_url} and #{second_url} np",
            :created_at => Time.at(1),
            :to_user    => nil
          }
          Support.expects(:humanize_time_diff).returns([2, "secs"])
          @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
Links: \e[36m#{first_url}\e[0m and \e[36m#{second_url}\e[0m np

          END
          )
          @ui.show_record(record)
        end
      end

      should "highlight usernames in a status" do
        from_user = "barman"
        users = %w{@fooman @barbaz @spoonman}
        record = {
          :from_user  => from_user,
          :status     => "I salute you #{users[0]}, #{users[1]}, and #{users[2]}!",
          :created_at => Time.at(1),
          :to_user    => nil
        }
        Support.expects(:humanize_time_diff).returns([2, "secs"])
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
I salute you \e[33m#{users[0]}\e[0m, \e[33m#{users[1]}\e[0m, and \e[33m#{users[2]}\e[0m!

        END
        )
        @ui.show_record(record)
      end

      should "not highlight email addresses as usernames in a status" do
        from_user = "barman"
        users = %w{@fooman @barbaz}
        email = "barbaz@foo.net"
        record = {
          :from_user  => from_user,
          :status     => "Hi, #{users[0]}! You should notify #{users[1]}, #{email}",
          :created_at => Time.at(1),
          :to_user    => nil
        }
        Support.expects(:humanize_time_diff).returns([2, "secs"])
        @out.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
Hi, \e[33m#{users[0]}\e[0m! You should notify \e[33m#{users[1]}\e[0m, #{email}

        END
        )
        @ui.show_record(record)
      end
    end
  end

  context "username regex" do
    should "match a proper username reference" do
      assert_full_match UI::USERNAME_REGEX, "@nick"
      assert_full_match UI::USERNAME_REGEX, "@nick_man"
      assert_full_match UI::USERNAME_REGEX, "@nick"
      assert_full_match UI::USERNAME_REGEX, " @nick"
    end

    should "not match an inproper username reference" do
      assert_no_full_match UI::USERNAME_REGEX, "@"
      assert_no_full_match UI::USERNAME_REGEX, "nick"
      assert_no_full_match UI::USERNAME_REGEX, "-@nick"
      assert_no_full_match UI::USERNAME_REGEX, "@nick-man"
      assert_no_full_match UI::USERNAME_REGEX, "@nick "
      assert_no_full_match UI::USERNAME_REGEX, " @nick "
      assert_no_full_match UI::USERNAME_REGEX, "man @nick"
      assert_no_full_match UI::USERNAME_REGEX, "man@nick"
    end
  end

  context "hashtag regex" do
    should "match a proper hashtag reference" do
      assert_full_match UI::HASHTAG_REGEX, "#mayhem"
      assert_full_match UI::HASHTAG_REGEX, "#friday_mayhem"
      assert_full_match UI::HASHTAG_REGEX, "#friday-mayhem"
    end

    should "not match an inproper hashtag reference" do
      assert_no_full_match UI::USERNAME_REGEX, "#"
      assert_no_full_match UI::USERNAME_REGEX, "mayhem"
      assert_no_full_match UI::USERNAME_REGEX, " #mayhem"
      assert_no_full_match UI::USERNAME_REGEX, "#mayhem "
      assert_no_full_match UI::USERNAME_REGEX, " #mayhem "
    end
  end
end

end
