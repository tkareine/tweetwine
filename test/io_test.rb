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
      @io.show(record)
    end

    should "output record as a status when status is given, without in-reply info" do
      record = {
        :user   => "fooman",
        :status => {
          :created_at => Time.at(1),
          :text       => "Hi, @barman! Lulz woo!"
        }
      }
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
fooman, 2 secs ago:
Hi, @barman! Lulz woo!

      END
      )
      @io.show(record)
    end

    should "output record as a status when status is given, with in-reply info" do
      record = {
        :user   => "barman",
        :status => {
          :created_at   => Time.at(1),
          :text         => "Hi, @fooman! Check this: http://www.foo.com. Nice, isn't it?",
          :in_reply_to  => "fooman"
        }
      }
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
barman, in reply to fooman, 2 secs ago:
Hi, @fooman! Check this: http://www.foo.com. Nice, isn't it?

      END
      )
      @io.show(record)
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
      @io.show(record)
    end

    should "output record as a status when status is given, without in-reply info" do
      record = {
        :user   => "fooman",
        :status => {
          :created_at => Time.at(1),
          :text       => "Hi, @barman! Lulz woo!"
        }
      }
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
\033[32mfooman\033[0m, 2 secs ago:
Hi, \033[33m@barman\033[0m! Lulz woo!

      END
      )
      @io.show(record)
    end

    should "output record as a status when status is given, with in-reply info" do
      record = {
        :user   => "barman",
        :status => {
          :created_at   => Time.at(1),
          :text         => "Hi, @fooman! Check this: http://www.foo.com. Nice, isn't it?",
          :in_reply_to  => "fooman"
        }
      }
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
\033[32mbarman\033[0m, in reply to \033[32mfooman\033[0m, 2 secs ago:
Hi, \033[33m@fooman\033[0m! Check this: \033[36mhttp://www.foo.com\033[0m. Nice, isn't it?

      END
      )
      @io.show(record)
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

  context "URL regex" do
    should "match an IP" do
      assert_full_match IO::URL_REGEX, "http://127.0.0.1"
      assert_full_match IO::URL_REGEX, "http://127.0.0.1/"
      assert_full_match IO::URL_REGEX, "https://127.0.0.1"
      assert_full_match IO::URL_REGEX, "https://127.0.0.1/"
    end

    should "match a FQDN" do
      assert_full_match IO::URL_REGEX, "https://fo.com"
      assert_full_match IO::URL_REGEX, "https://fo.com/"
      assert_full_match IO::URL_REGEX, "http://www.foo.com"
      assert_full_match IO::URL_REGEX, "http://www.foo.com/"
      assert_full_match IO::URL_REGEX, "https://www.foo.com"
      assert_full_match IO::URL_REGEX, "https://www.foo.com/"
    end

    should "respect whitespace, parentheses, periods, etc. at the end" do
      assert_full_match IO::URL_REGEX, "http://tr.im/WGAP"
      assert_no_full_match IO::URL_REGEX, "http://tr.im/WGAP "
      assert_no_full_match IO::URL_REGEX, "http://tr.im/WGAP)"
      assert_no_full_match IO::URL_REGEX, "http://tr.im/WGAP."
      assert_no_full_match IO::URL_REGEX, "http://tr.im/WGAP,"
    end

    should "match multipart URLs" do
      assert_full_match IO::URL_REGEX, "http://technomancy.us/126"
      assert_full_match IO::URL_REGEX, "http://technomancy.us/126/"
      assert_full_match IO::URL_REGEX, "http://bit.ly/18rUVx"
      assert_full_match IO::URL_REGEX, "http://bit.ly/18rUVx/"
      assert_full_match IO::URL_REGEX, "http://bit.ly/18rU_Vx"
      assert_full_match IO::URL_REGEX, "http://bit.ly/18rU_Vx/"
      assert_full_match IO::URL_REGEX, "http://www.ireport.com/docs/DOC-266869"
      assert_full_match IO::URL_REGEX, "http://www.ireport.com/docs/DOC-266869/"
    end
  end
end

end
