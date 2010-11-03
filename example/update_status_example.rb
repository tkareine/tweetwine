# coding: utf-8

require "example_helper"
require "yaml"

Feature "update my status (send new tweet)" do
  in_order_to "tell something about me to the world"
  as_a "authenticated user"
  i_want_to "update my status"

  STATUS_WITHOUT_URLS = "bored. going to sleep."
  BODY_WITHOUT_URLS = "status=bored.%20going%20to%20sleep."
  UPDATE_URL = "https://api.twitter.com/1/statuses/update.json"
  UPDATE_FIXTURE_WITHOUT_URLS = fixture("update_without_urls.json")
  UPDATE_FIXTURE_UTF8 = fixture("update_utf8.json")

  Scenario "update my status from command line with colorization disabled" do
    When "I start the application with 'update' command with --no-colors option, give status in single command line argument, and confirm" do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      @output = start_cli %W{--no-colors update #{STATUS_WITHOUT_URLS}}, "y"
    end

    Then "the application sends and shows the status" do
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == STATUS_WITHOUT_URLS
    end
  end

  Scenario "update my status from command line with colorization enabled" do
    When "I start the application with 'update' command with --colors option, give status in single command line argument, and confirm" do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      @output = start_cli %W{--colors update #{STATUS_WITHOUT_URLS}}, "y"
    end

    Then "the application sends and shows the status" do
      @output[5].should == "\e[32m#{USER}\e[0m, 9 hours ago:"
      @output[6].should == STATUS_WITHOUT_URLS
    end
  end

  Scenario "update my status from command line when message is spread over multiple arguments" do
    When "I start the application with 'update' command, give status in multiple command line arguments, and confirm" do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      @output = start_cli(%w{--no-colors update} + STATUS_WITHOUT_URLS.split, "y")
    end

    Then "the application sends and shows the status" do
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == STATUS_WITHOUT_URLS
    end
  end

  Scenario "cancel status update from command line" do
    When "I start the application with 'update' command, and cancel" do
      @output = start_cli %W{--no-colors update #{STATUS_WITHOUT_URLS}}, "n"
    end

    Then "the application shows a cancellation message" do
      @output[3].should =~ /Cancelled./
    end
  end

  Scenario "update my status from STDIN" do
    When "I start the application with 'update' command, give status from STDIN, and confirm" do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      @output = start_cli %w{update}, STATUS_WITHOUT_URLS, "y"
    end

    Then "the application sends and shows the status" do
      @output[0].should == "Status update: "
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == STATUS_WITHOUT_URLS
    end
  end

  Scenario "cancel a status update from STDIN" do
    When "I start the application with 'update' command, give status from STDIN, and cancel" do
      @output = start_cli %w{update}, STATUS_WITHOUT_URLS, "n"
    end

    Then "the application shows a cancellation message" do
      @output[3].should =~ /Cancelled./
    end
  end

  if "".respond_to?(:encode)
    Scenario "encode status in UTF-8 (String supports encoding)" do
      When "I start the application with 'update' command, input latin1 encoded status, and confirm" do
        @status_utf8 = "résumé"
        @status_latin1 = @status_utf8.encode('ISO-8859-1')
        url_encoded_body = "status=r%c3%a9sum%c3%a9"
        stub_http_request(:post, UPDATE_URL).with(:body => url_encoded_body).to_return(:body => UPDATE_FIXTURE_UTF8)
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
      When "I have latin1 in LANG envar, start the application with 'update' command, input status, and confirm" do
        @status_latin1 = "r\xe9sum\xe9"
        @status_utf8 = "r\xc3\xa9sum\xc3\xa9"
        url_encoded_body = "status=r%c3%a9sum%c3%a9"
        stub_http_request(:post, UPDATE_URL).with(:body => url_encoded_body).to_return(:body => UPDATE_FIXTURE_UTF8)
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

  Scenario "shorten URLs in status" do
    When "I have configured URL shortening, start the application with 'update' command, input status containing URLs, and confirm" do
      shorten_config = read_shorten_config
      @urls = {
        :rubygems => {
          :full     => 'http://rubygems.org/',
          :full_enc => 'http%3a%2f%2frubygems.org%2f',
          :short    => 'http://is.gd/gGazV',
          :body     => "#{shorten_config['url_param_name']}=http%3a%2f%2frubygems.org%2f",
          :fixture  => 'shorten_rubygems.html'
        },
        :rubylang => {
          :full     => 'http://ruby-lang.org/',
          :full_enc => 'http%3a%2f%2fruby-lang.org%2f',
          :short    => 'http://is.gd/gGaM3',
          :body     => "#{shorten_config['url_param_name']}=http%3a%2f%2fruby-lang.org%2f",
          :fixture  => 'shorten_rubylang.html'
        }
      }
      @send_status = "ruby links: #{@urls[:rubygems][:full]} #{@urls[:rubylang][:full]}"
      update_body = "status=ruby%20links%3a%20#{@urls[:rubygems][:full_enc]}%20#{@urls[:rubylang][:full_enc]}"
      update_fixture = fixture("update_with_urls.json")
      stub_http_request(shorten_config['method'].to_sym, shorten_config['service_url']).
          with(:body => @urls[:rubygems][:body]).
          to_return(:body => @urls[:rubygems][:fixture])
      stub_http_request(shorten_config['method'].to_sym, shorten_config['service_url']).
          with(:body => @urls[:rubylang][:body]).
          to_return(:body => @urls[:rubylang][:fixture])
      stub_http_request(:post, UPDATE_URL).
          with(:body => update_body).
          to_return(:body => update_fixture)
      @output = start_cli %W{--no-colors update #{@send_status}}, "y"
    end

    Then "the application shortens the URLs in the status before sending it" do
      @output[1].should == @send_status
      @output[5].should == "#{USER}, 9 hours ago:"
      @output[6].should == "ruby links: #{@urls[:rubygems][:short]} #{@urls[:rubylang][:short]}"
    end
  end

  private

  def read_shorten_config
    YAML.load_file(CONFIG_FILE)['shorten_urls']
  end
end
