# coding: utf-8

require "example_helper"

Feature "update my status (send new tweet)" do
  in_order_to "tell something about me to the world"
  as_a "authenticated user"
  i_want_to "update my status"

  STATUS = "bored. going to sleep."
  URL_ENCODED_BODY = "status=bored.%20going%20to%20sleep."

  Scenario "update my status from command line with colorization disabled" do
    When "I start the application with 'update' command" do
      stub_http_request(:post, "https://api.twitter.com/1/statuses/update.json").with(:body => URL_ENCODED_BODY).to_return(:body => fixture("update.json"))
      @output = start_cli %W{--no-colors update #{STATUS}}, "y"
    end

    Then "the application sends and shows the status" do
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == "#{STATUS}"
    end
  end

  Scenario "update my status from command line with colorization enabled" do
    When "I start the application with 'update' command" do
      stub_http_request(:post, "https://api.twitter.com/1/statuses/update.json").with(:body => URL_ENCODED_BODY).to_return(:body => fixture("update.json"))
      @output = start_cli %W{--colors update #{STATUS}}, "y"
    end

    Then "the application sends and shows the status" do
      @output[5].should == "\e[32m#{USER}\e[0m, 9 hours ago:"
      @output[6].should == "#{STATUS}"
    end
  end

  Scenario "update my status from command line when message is spread over multiple arguments" do
    When "I start the application with 'update' command" do
      stub_http_request(:post, "https://api.twitter.com/1/statuses/update.json").with(:body => URL_ENCODED_BODY).to_return(:body => fixture("update.json"))
      @output = start_cli(%w{--no-colors update} + STATUS.split, "y")
    end

    Then "the application sends and shows the status" do
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == "#{STATUS}"
    end
  end

  Scenario "cancel status update from command line" do
    When "I start the application with 'update' command" do
      @output = start_cli(%w{update} + STATUS.split, "n")
    end

    Then "the application shows a cancellation message" do
      @output[3].should =~ /Cancelled./
    end
  end

  Scenario "update my status from STDIN" do
    When "I start the application with 'update' command" do
      stub_http_request(:post, "https://api.twitter.com/1/statuses/update.json").with(:body => URL_ENCODED_BODY).to_return(:body => fixture("update.json"))
      @output = start_cli %w{update}, STATUS, "y"
    end

    Then "the application sends and shows the status" do
      @output[0].should == "Status update: "
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == "#{STATUS}"
    end
  end

  Scenario "cancel a status update from STDIN" do
    When "I start the application with 'update' command" do
      @output = start_cli %w{update}, STATUS, "n"
    end

    Then "the application shows a cancellation message" do
      @output[3].should =~ /Cancelled./
    end
  end

  if "".respond_to?(:encode)
    Scenario "encode status in UTF-8 (String supports encoding)" do
      When "I start the application with 'update' command" do
        @status_utf8 = "résumé"
        @status_latin1 = @status_utf8.encode('ISO-8859-1')
        url_encoded_body = "status=r%c3%a9sum%c3%a9"
        stub_http_request(:post, "https://api.twitter.com/1/statuses/update.json").with(:body => url_encoded_body).to_return(:body => fixture("update_utf8.json"))
        @output = start_cli %W{--no-colors update #{@status_latin1}}, "y"
      end

      Then "the application sends and shows the status" do
        # NOTE: Should be in latin-1, but StringIO converts it to UTF-8. At
        # least on tty Ruby 1.9.2 outputs it in latin-1.
        #@output[1].should == @status_latin1   # preview
        @output[5].should == "#{USER}, 9 hours ago:"
        @output[6].should == @status_utf8
      end
    end
  else
    Scenario "encode status in UTF-8 (String does not support encoding)" do
      When "I start the application with 'update' command" do
        @status_latin1 = "r\xe9sum\xe9"
        @status_utf8 = "r\xc3\xa9sum\xc3\xa9"
        url_encoded_body = "status=r%c3%a9sum%c3%a9"
        stub_http_request(:post, "https://api.twitter.com/1/statuses/update.json").with(:body => url_encoded_body).to_return(:body => fixture("update_utf8.json"))
        tmp_kcode('NONE') do
          tmp_env(:LANG => 'latin1') do
            Tweetwine::CharacterEncoding.forget_guess
            @output = start_cli %W{--no-colors update #{@status_latin1}}, "y"
          end
        end
      end

      Then "the application sends and shows the status" do
        @output[1].should == @status_latin1   # preview
        @output[5].should == "#{USER}, 9 hours ago:"
        # TODO: we should convert status back to latin-1
        @output[6].should == @status_utf8
      end
    end
  end
end
