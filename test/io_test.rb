require File.dirname(__FILE__) << "/test_helper"

module Tweetwine

class IOTest < Test::Unit::TestCase
  context "An IO" do
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
  end

  context "An IO, with colorization disabled" do
    setup do
      @input = mock()
      @output = mock()
      @io = IO.new({ :input => @input, :output => @output, :colorize => false })
    end

    should "output a record as user info when no status is given" do
      record = { :user => "fooman" }
      @output.expects(:puts).with(<<-END
fooman

      END
      )
      @io.show_record(record)
    end

    should "output a record as status info when status is given, without in-reply info" do
      status = "Hi, @barman! Lulz woo!"
      record = {
        :user   => "fooman",
        :status => {
          :created_at => Time.at(1),
          :text       => status
        }
      }
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
fooman, 2 secs ago:
#{status}

      END
      )
      @io.show_record(record)
    end

    should "output a record as status info when status is given, with in-reply info" do
      status = "Hi, @fooman! How are you doing?"
      record = {
        :user   => "barman",
        :status => {
          :created_at   => Time.at(1),
          :text         => status,
          :in_reply_to  => "fooman"
        }
      }
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
barman, in reply to fooman, 2 secs ago:
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

  context "An IO, with colorization enabled" do
    setup do
      @input = mock()
      @output = mock()
      @io = IO.new({ :input => @input, :output => @output, :colorize => true })
    end

    should "output a record as user info when no status is given" do
      record = { :user => "fooman" }
      @output.expects(:puts).with(<<-END
\033[32mfooman\033[0m

      END
      )
      @io.show_record(record)
    end

    should "output a record as status info when status is given, without in-reply info" do
      record = {
        :user   => "fooman",
        :status => {
          :created_at => Time.at(1),
          :text       => "Wondering the meaning of life."
        }
      }
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
\033[32mfooman\033[0m, 2 secs ago:
Wondering the meaning of life.

      END
      )
      @io.show_record(record)
    end

    should "output a record as status info when status is given, with in-reply info" do
      record = {
        :user   => "barman",
        :status => {
          :created_at   => Time.at(1),
          :text         => "Hi, @fooman! How are you doing?",
          :in_reply_to  => "fooman"
        }
      }
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
\033[32mbarman\033[0m, in reply to \033[32mfooman\033[0m, 2 secs ago:
Hi, \033[33m@fooman\033[0m! How are you doing?

      END
      )
      @io.show_record(record)
    end

    should "output a preview of a status" do
      status = "@nick, check http://bit.ly/18rU_Vx"
      @output.expects(:puts).with(<<-END

\033[33m@nick\033[0m, check \033[36mhttp://bit.ly/18rU_Vx\033[0m

      END
      )
      @io.show_status_preview(status)
    end

    should "highlight HTTP and HTTPS URIs in a status" do
      record = {
        :user   => "barman",
        :status => {
          :created_at   => Time.at(1),
          :text         => "Three links: http://bit.ly/18rU_Vx http://is.gd/1qLk3 and https://is.gd/2rLk4",
        }
      }
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
\033[32mbarman\033[0m, 2 secs ago:
Three links: \033[36mhttp://bit.ly/18rU_Vx\033[0m \033[36mhttp://is.gd/1qLk3\033[0m and \033[36mhttps://is.gd/2rLk4\033[0m

      END
      )
      @io.show_record(record)
    end

    should "highlight nicks in a status" do
      record = {
        :user   => "barman",
        :status => {
          :created_at   => Time.at(1),
          :text         => "I salute you @fooman, @barbaz, and @spoonman!",
        }
      }
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
\033[32mbarman\033[0m, 2 secs ago:
I salute you \033[33m@fooman\033[0m, \033[33m@barbaz\033[0m, and \033[33m@spoonman\033[0m!

      END
      )
      @io.show_record(record)
    end
  end

  context "Nick regex" do
    should "match a proper nick reference" do
      assert_full_match IO::NICK_REGEX, "@nick"
      assert_full_match IO::NICK_REGEX, "@nick_man"
    end

    should "not match an inproper nick reference" do
      assert_no_full_match IO::NICK_REGEX, "@"
      assert_no_full_match IO::NICK_REGEX, "nick"
      assert_no_full_match IO::NICK_REGEX, "@nick-man"
    end
  end
end

end
