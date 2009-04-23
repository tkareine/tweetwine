require File.dirname(__FILE__) << "/test_helper"

class IOTest < Test::Unit::TestCase
  include Tweetwine

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

    should "print statuses, with colorization off" do
      statuses = [
        {
          "created_at" => Time.at(1),
          "user" => { "screen_name" => "fooman" },
          "text" => "Hi, @barman! Lulz woo!"
        }
      ]
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
fooman, 2 secs ago:
Hi, @barman! Lulz woo!

      END
      )
      @io.show_statuses(statuses)
    end
  end

  context "An IO, with colorization enabled" do
    setup do
      @input = mock()
      @output = mock()
      @io = IO.new({ :input => @input, :output => @output, :colorize => true })
    end

    should "print statuses, with colorization off" do
      statuses = [
        {
          "created_at" => Time.at(1),
          "user" => { "screen_name" => "fooman" },
          "text" => "Hi, @barman! Lulz woo!"
        }
      ]
      Util.expects(:humanize_time_diff).returns([2, "secs"])
      @output.expects(:puts).with(<<-END
\033[32mfooman\033[0m, 2 secs ago:
Hi, \033[31m@barman\033[0m! Lulz woo!

      END
      )
      @io.show_statuses(statuses)
    end
  end
end
