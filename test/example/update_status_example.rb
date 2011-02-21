# coding: utf-8

require "example_helper"
require "yaml"

Feature "update my status (send new tweet)" do
  as_a "authenticated user"
  i_want_to "update my status"
  in_order_to "tell something about me to the world"

  RUBYGEMS_FIXTURE = fixture_file('shorten_rubygems.html')
  RUBYGEMS_FULL_URL = 'http://rubygems.org/'
  RUBYGEMS_FULL_URL_ENC = 'http%3a%2f%2frubygems.org%2f'
  RUBYGEMS_SHORT_URL = 'http://is.gd/gGazV'
  RUBYGEMS_SHORT_URL_ENC = 'http%3a%2f%2fis.gd%2fgGazV'
  RUBYLANG_FIXTURE = fixture_file('shorten_rubylang.html')
  RUBYLANG_FULL_URL = 'http://ruby-lang.org/'
  RUBYLANG_FULL_URL_ENC = 'http%3a%2f%2fruby-lang.org%2f'
  RUBYLANG_SHORT_URL = 'http://is.gd/gGaM3'
  RUBYLANG_SHORT_URL_ENC = 'http%3a%2f%2fis.gd%2fgGaM3'
  SHORTEN_CONFIG = read_shorten_config
  SHORTEN_METHOD = SHORTEN_CONFIG[:method].to_sym
  STATUS_WITH_FULL_URLS = "ruby links: #{RUBYGEMS_FULL_URL} #{RUBYLANG_FULL_URL}"
  STATUS_WITH_SHORT_URLS = "ruby links: #{RUBYGEMS_SHORT_URL} #{RUBYLANG_SHORT_URL}"
  STATUS_WITHOUT_URLS = "bored. going to sleep."
  UPDATE_FIXTURE_WITH_URLS = fixture_file('update_with_urls.json')
  UPDATE_FIXTURE_WITHOUT_URLS = fixture_file('update_without_urls.json')
  UPDATE_FIXTURE_UTF8 = fixture_file('update_utf8.json')
  UPDATE_URL = "https://api.twitter.com/1/statuses/update.json"

  BODY_WITH_SHORT_URLS = "status=ruby%20links%3a%20#{RUBYGEMS_SHORT_URL_ENC}%20#{RUBYLANG_SHORT_URL_ENC}"
  BODY_WITHOUT_URLS = "status=bored.%20going%20to%20sleep."

  Scenario "update my status from command line with colorization disabled" do
    When "I start the application with 'update' command with --no-colors option, give status in single command line argument, and confirm" do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      @output = start_cli %W{--no-colors update #{STATUS_WITHOUT_URLS}}, %w{y}
    end

    Then "the application sends and shows the status" do
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == STATUS_WITHOUT_URLS
    end
  end

  Scenario "update my status from command line with colorization enabled" do
    When "I start the application with 'update' command with --colors option, give status in single command line argument, and confirm" do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      @output = start_cli %W{--colors update #{STATUS_WITHOUT_URLS}}, %w{y}
    end

    Then "the application sends and shows the status" do
      @output[5].should == "\e[32m#{USER}\e[0m, 9 hours ago:"
      @output[6].should == STATUS_WITHOUT_URLS
    end
  end

  Scenario "update my status from command line when message is spread over multiple arguments" do
    When "I start the application with 'update' command, give status in multiple command line arguments, and confirm" do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      @output = start_cli(%w{--no-colors update} + STATUS_WITHOUT_URLS.split, %w{y})
    end

    Then "the application sends and shows the status" do
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == STATUS_WITHOUT_URLS
    end
  end

  Scenario "cancel status update from command line" do
    When "I start the application with 'update' command, and cancel" do
      @output = start_cli %W{--no-colors update #{STATUS_WITHOUT_URLS}}, %w{n}
    end

    Then "the application shows a cancellation message" do
      @output[3].should =~ /Cancelled./
    end
  end

  Scenario "update my status from STDIN" do
    When "I start the application with 'update' command, give status from STDIN, and confirm" do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      @output = start_cli %w{update}, [STATUS_WITHOUT_URLS, 'y']
    end

    Then "the application sends and shows the status" do
      @output[0].should == "Status update: "
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == STATUS_WITHOUT_URLS
    end
  end

  Scenario "cancel a status update from STDIN" do
    When "I start the application with 'update' command, give status from STDIN, and cancel" do
      @output = start_cli %w{update}, [STATUS_WITHOUT_URLS, 'n']
    end

    Then "the application shows a cancellation message" do
      @output[3].should =~ /Cancelled./
    end
  end

  if defined? Encoding
    Scenario "encode status in UTF-8 (String supports encoding)" do
      When "I start the application with 'update' command, input latin1 encoded status, and confirm" do
        @status_utf8 = "résumé"
        @status_latin1 = @status_utf8.encode('ISO-8859-1')
        url_encoded_body = "status=r%c3%a9sum%c3%a9"
        stub_http_request(:post, UPDATE_URL).with(:body => url_encoded_body).to_return(:body => UPDATE_FIXTURE_UTF8)
        @output = start_cli %W{--no-colors update #{@status_latin1}}, %w{y}
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
      When "I have latin1 in LANG envar, start the application with 'update' command, input status, and confirm" do
        @status_latin1 = "r\xe9sum\xe9"
        @status_utf8 = "r\xc3\xa9sum\xc3\xa9"
        url_encoded_body = "status=r%c3%a9sum%c3%a9"
        stub_http_request(:post, UPDATE_URL).with(:body => url_encoded_body).to_return(:body => UPDATE_FIXTURE_UTF8)
        tmp_kcode('NONE') do
          tmp_env(:LANG => 'latin1') do
            Tweetwine::CharacterEncoding.forget_guess
            @output = start_cli %W{--no-colors update #{@status_latin1}}, %w{y}
          end
        end
      end

      Then "the application sends and shows the status" do
        @output[1].should == @status_latin1   # preview
        @output[5].should == "#{USER}, 9 hours ago:"
        @output[6].should == @status_utf8
      end
    end
  end

  Scenario "shorten URLs in status update" do
    When "I have configured URL shortening, start the application with 'update' command, input status containing URLs, and confirm" do
      @shorten_rubygems_body = "#{SHORTEN_CONFIG[:url_param_name]}=#{RUBYGEMS_FULL_URL_ENC}"
      @shorten_rubylang_body = "#{SHORTEN_CONFIG[:url_param_name]}=#{RUBYLANG_FULL_URL_ENC}"
      stub_http_request(SHORTEN_METHOD, SHORTEN_CONFIG[:service_url]).
        with(:body => @shorten_rubygems_body).
        to_return(:body => RUBYGEMS_FIXTURE)
      stub_http_request(SHORTEN_METHOD, SHORTEN_CONFIG[:service_url]).
        with(:body => @shorten_rubylang_body).
        to_return(:body => RUBYLANG_FIXTURE)
      stub_http_request(:post, UPDATE_URL).
        with(:body => BODY_WITH_SHORT_URLS).
        to_return(:body => UPDATE_FIXTURE_WITH_URLS)
      @output = start_cli %W{--no-colors update #{STATUS_WITH_FULL_URLS}}, %w{y}
    end

    Then "the application shortens the URLs in the status before sending it" do
      assert_requested(SHORTEN_METHOD, SHORTEN_CONFIG[:service_url], :body => @shorten_rubygems_body)
      assert_requested(SHORTEN_METHOD, SHORTEN_CONFIG[:service_url], :body => @shorten_rubylang_body)
      @output[1].should == STATUS_WITH_SHORT_URLS
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == STATUS_WITH_SHORT_URLS
    end
  end

  Scenario "disable URL shortening for status updates" do
    When "I have configured URL shortening, start the application with 'update' command with --no-url-shorten option, input status containing URLs, and confirm" do
      stub_http_request(:post, UPDATE_URL).
        with(:body => BODY_WITH_SHORT_URLS).
        to_return(:body => UPDATE_FIXTURE_WITH_URLS)
      @output = start_cli %W{--no-colors --no-url-shorten update #{STATUS_WITH_SHORT_URLS}}, %w{y}
    end

    Then "the application passes URLs as is in the status" do
      @output[1].should == STATUS_WITH_SHORT_URLS
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == STATUS_WITH_SHORT_URLS
    end
  end
end
