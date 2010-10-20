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
end
