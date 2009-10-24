require "test_helper"

module Tweetwine

class IOTest < Test::Unit::TestCase
  context "An IO instance" do
    setup do
      @input = mock()
      @output = mock()
      @io = IO.new({ :input => @input, :output => @output })
    end

    should "output prompt and return input as trimmed" do
      @output.expects(:print).with("The answer: ")
      @input.expects(:gets).returns("  42 ")
      assert_equal "42", @io.prompt("The answer")
    end

    should "output info message" do
      @output.expects(:puts).with("foo")
      @io.info("foo")
    end

    should "output warning message" do
      @output.expects(:puts).with("Warning: monkey patching ahead")
      @io.warn("monkey patching ahead")
    end

    should "confirm action, with positive answer" do
      @output.expects(:print).with("Fire nukes? [yN] ")
      @input.expects(:gets).returns("y")
      assert_equal true, @io.confirm("Fire nukes?")
    end

    should "confirm action, with negative answer" do
      @output.expects(:print).with("Fire nukes? [yN] ")
      @input.expects(:gets).returns("n")
      assert_equal false, @io.confirm("Fire nukes?")
    end

    should "confirm action, with default answer" do
      @output.expects(:print).with("Fire nukes? [yN] ")
      @input.expects(:gets).returns("")
      assert_equal false, @io.confirm("Fire nukes?")
    end

    context "with colorization disabled" do
      setup do
        @io = IO.new({ :input => @input, :output => @output, :colorize => false })
      end

      should "output a record as user info when no status is given" do
        from_user = "fooman"
        record = { :from_user => from_user }
        @output.expects(:puts).with(<<-END
#{from_user}

        END
        )
        @io.show_record(record)
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
        Util.expects(:humanize_time_diff).returns([2, "secs"])
        @output.expects(:puts).with(<<-END
#{from_user}, 2 secs ago:
#{status}

        END
        )
        @io.show_record(record)
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
        Util.expects(:humanize_time_diff).returns([2, "secs"])
        @output.expects(:puts).with(<<-END
#{from_user}, in reply to #{to_user}, 2 secs ago:
#{status}

        END
        )
        @io.show_record(record)
      end

      should "output a preview of a status" do
        status = "@nick, check http://bit.ly/18rU_Vx"
        @output.expects(:puts).with(<<-END

#{status}

        END
        )
        @io.show_status_preview(status)
      end
    end

    context "with colorization enabled" do
      setup do
        @io = IO.new({ :input => @input, :output => @output, :colorize => true })
      end

      should "output a record as user info when no status is given" do
        from_user = "fooman"
        record = { :from_user => from_user }
        @output.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m

        END
        )
        @io.show_record(record)
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
        Util.expects(:humanize_time_diff).returns([2, "secs"])
        @output.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
#{status}

        END
        )
        @io.show_record(record)
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
        Util.expects(:humanize_time_diff).returns([2, "secs"])
        @output.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, in reply to \e[32m#{to_user}\e[0m, 2 secs ago:
\e[33m@#{to_user}\e[0m! How are you doing?

        END
        )
        @io.show_record(record)
      end

      should "output a preview of a status" do
        status = "@nick, check http://bit.ly/18rU_Vx"
        @output.expects(:puts).with(<<-END

\e[33m@nick\e[0m, check \e[36mhttp://bit.ly/18rU_Vx\e[0m

        END
        )
        @io.show_status_preview(status)
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
        Util.expects(:humanize_time_diff).returns([2, "secs"])
        @output.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
Lulz, so happy! \e[35m#{hashtags[0]}\e[0m \e[35m#{hashtags[1]}\e[0m

        END
        )
        @io.show_record(record)
      end

      should "highlight HTTP and HTTPS URLs in a status" do
        from_user = "barman"
        links = %w{http://bit.ly/18rU_Vx http://is.gd/1qLk3 https://is.gd/2rLk4}
        record = {
          :from_user  => from_user,
          :status     => "Three links: #{links[0]} #{links[1]} and #{links[2]}",
          :created_at => Time.at(1),
          :to_user    => nil
        }
        Util.expects(:humanize_time_diff).returns([2, "secs"])
        @output.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
Three links: \e[36m#{links[0]}\e[0m \e[36m#{links[1]}\e[0m and \e[36m#{links[2]}\e[0m

        END
        )
        @io.show_record(record)
      end

      should "highlight HTTP and HTTPS URLs in a status, even if duplicates" do
        from_user = "barman"
        link = "http://is.gd/1qLk3"
        record = {
          :from_user  => from_user,
          :status     => "Duplicate links: #{link} and #{link}",
          :created_at => Time.at(1),
          :to_user    => nil
        }
        Util.expects(:humanize_time_diff).returns([2, "secs"])
        @output.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
Duplicate links: \e[36m#{link}\e[0m and \e[36m#{link}\e[0m

        END
        )
        @io.show_record(record)
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
        Util.expects(:humanize_time_diff).returns([2, "secs"])
        @output.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
I salute you \e[33m#{users[0]}\e[0m, \e[33m#{users[1]}\e[0m, and \e[33m#{users[2]}\e[0m!

        END
        )
        @io.show_record(record)
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
        Util.expects(:humanize_time_diff).returns([2, "secs"])
        @output.expects(:puts).with(<<-END
\e[32m#{from_user}\e[0m, 2 secs ago:
Hi, \e[33m#{users[0]}\e[0m! You should notify \e[33m#{users[1]}\e[0m, #{email}

        END
        )
        @io.show_record(record)
      end
    end
  end

  context "Username regex" do
    should "match a proper username reference" do
      assert_full_match IO::USERNAME_REGEX, "@nick"
      assert_full_match IO::USERNAME_REGEX, "@nick_man"
      assert_full_match IO::USERNAME_REGEX, "@nick"
      assert_full_match IO::USERNAME_REGEX, " @nick"
    end

    should "not match an inproper username reference" do
      assert_no_full_match IO::USERNAME_REGEX, "@"
      assert_no_full_match IO::USERNAME_REGEX, "nick"
      assert_no_full_match IO::USERNAME_REGEX, "-@nick"
      assert_no_full_match IO::USERNAME_REGEX, "@nick-man"
      assert_no_full_match IO::USERNAME_REGEX, "@nick "
      assert_no_full_match IO::USERNAME_REGEX, " @nick "
      assert_no_full_match IO::USERNAME_REGEX, "man @nick"
      assert_no_full_match IO::USERNAME_REGEX, "man@nick"
    end
  end

  context "Hashtag regex" do
    should "match a proper hashtag reference" do
      assert_full_match IO::HASHTAG_REGEX, "#mayhem"
      assert_full_match IO::HASHTAG_REGEX, "#friday_mayhem"
      assert_full_match IO::HASHTAG_REGEX, "#friday-mayhem"
    end

    should "not match an inproper hashtag reference" do
      assert_no_full_match IO::USERNAME_REGEX, "#"
      assert_no_full_match IO::USERNAME_REGEX, "mayhem"
      assert_no_full_match IO::USERNAME_REGEX, " #mayhem"
      assert_no_full_match IO::USERNAME_REGEX, "#mayhem "
      assert_no_full_match IO::USERNAME_REGEX, " #mayhem "
    end
  end
end

end
