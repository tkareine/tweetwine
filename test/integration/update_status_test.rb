# coding: utf-8

require 'support/integration_test_case'
require 'yaml'

module Tweetwine::Test::Integration

class UpdateStatusTest < TestCase
  RUBYGEMS_FIXTURE            = fixture_file 'shorten_rubygems.html'
  RUBYGEMS_FULL_URL           = 'http://rubygems.org/'
  RUBYGEMS_SHORT_URL          = 'http://is.gd/gGazV'
  RUBYLANG_FIXTURE            = fixture_file 'shorten_rubylang.html'
  RUBYLANG_FULL_URL           = 'http://ruby-lang.org/'
  RUBYLANG_SHORT_URL          = 'http://is.gd/gGaM3'
  SHORTEN_CONFIG              = read_shorten_config
  SHORTEN_METHOD              = SHORTEN_CONFIG[:method].to_sym
  STATUS_WITH_FULL_URLS       = "ruby links: #{RUBYGEMS_FULL_URL} #{RUBYLANG_FULL_URL}"
  STATUS_WITH_SHORT_URLS      = "ruby links: #{RUBYGEMS_SHORT_URL} #{RUBYLANG_SHORT_URL}"
  STATUS_WITHOUT_URLS         = "bored. going to sleep."
  UPDATE_FIXTURE_WITH_URLS    = fixture_file 'update_with_urls.json'
  UPDATE_FIXTURE_WITHOUT_URLS = fixture_file 'update_without_urls.json'
  UPDATE_FIXTURE_UTF8         = fixture_file 'update_utf8.json'
  UPDATE_URL                  = "https://api.twitter.com/1/statuses/update.json"

  BODY_WITH_SHORT_URLS  = { 'status' => "ruby links: #{RUBYGEMS_SHORT_URL} #{RUBYLANG_SHORT_URL}" }
  BODY_WITHOUT_URLS     = { 'status' => 'bored. going to sleep.' }

  describe "update my status from command line with colorization disabled" do
    before do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      at_snapshot do
        @output = start_cli %W{--no-colors update #{STATUS_WITHOUT_URLS}}, %w{y}
      end
    end

    it "sends and shows the status" do
      @output[5].must_equal "#{USER}, 9 hours ago:"
      @output[6].must_equal STATUS_WITHOUT_URLS
    end
  end

  describe "update my status from command line with colorization enabled" do
    before do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      at_snapshot do
        @output = start_cli %W{--colors update #{STATUS_WITHOUT_URLS}}, %w{y}
      end
    end

    it "sends and shows the status" do
      @output[5].must_equal "\e[32m#{USER}\e[0m, 9 hours ago:"
      @output[6].must_equal STATUS_WITHOUT_URLS
    end
  end

  describe "update my status from command line when message is spread over multiple arguments" do
    before do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      at_snapshot do
        @output = start_cli(%w{--no-colors update} + STATUS_WITHOUT_URLS.split, %w{y})
      end
    end

    it "sends and shows the status" do
      @output[5].must_equal "#{USER}, 9 hours ago:"
      @output[6].must_equal STATUS_WITHOUT_URLS
    end
  end

  describe "cancel status update from command line" do
    before do
      @output = start_cli %W{--no-colors update #{STATUS_WITHOUT_URLS}}, %w{n}
    end

    it "shows cancellation message" do
      @output[3].must_match(/Cancelled./)
    end
  end

  describe "update my status from STDIN" do
    before do
      stub_http_request(:post, UPDATE_URL).with(:body => BODY_WITHOUT_URLS).to_return(:body => UPDATE_FIXTURE_WITHOUT_URLS)
      at_snapshot do
        @output = start_cli %w{update}, [STATUS_WITHOUT_URLS, 'y']
      end
    end

    it "sends and shows the status" do
      @output[0].must_equal "Status update: "
      @output[5].must_equal "#{USER}, 9 hours ago:"
      @output[6].must_equal STATUS_WITHOUT_URLS
    end
  end

  describe "cancel a status update from STDIN" do
    before do
      @output = start_cli %w{update}, [STATUS_WITHOUT_URLS, 'n']
    end

    it "shows a cancellation message" do
      @output[3].must_match(/Cancelled./)
    end
  end

  if defined? Encoding
    describe "encode status in UTF-8 (String supports encoding)" do
      before do
        @status_utf8 = "résumé"
        @status_latin1 = @status_utf8.encode('ISO-8859-1')
        stub_http_request(:post, UPDATE_URL).with(:body => { 'status' => @status_utf8 }).to_return(:body => UPDATE_FIXTURE_UTF8)
        at_snapshot do
          @output = start_cli %W{--no-colors update #{@status_latin1}}, %w{y}
        end
      end

      it "sends and shows the status" do
        # NOTE: Should be in latin-1, but StringIO converts it to UTF-8. At
        # least on tty Ruby 1.9.2 outputs it in latin-1.
        #@output[1].should == @status_latin1   # preview
        @output[5].must_equal "#{USER}, 9 hours ago:"
        @output[6].must_equal @status_utf8
      end
    end
  else
    describe "encode status in UTF-8 (String does not support encoding)" do
      before do
        @status_latin1 = "r\xe9sum\xe9"
        @status_utf8 = "r\xc3\xa9sum\xc3\xa9"
        stub_http_request(:post, UPDATE_URL).with(:body => { 'status' => @status_utf8 }).to_return(:body => UPDATE_FIXTURE_UTF8)
        tmp_kcode('NONE') do
          tmp_env(:LANG => 'latin1') do
            Tweetwine::CharacterEncoding.forget_guess
            at_snapshot do
              @output = start_cli %W{--no-colors update #{@status_latin1}}, %w{y}
            end
          end
        end
      end

      it "sends and shows the status" do
        @output[1].must_equal @status_latin1   # preview
        @output[5].must_equal "#{USER}, 9 hours ago:"
        @output[6].must_equal @status_utf8
      end
    end
  end

  describe "shorten URLs in status update" do
    before do
      @shorten_rubygems_body = { SHORTEN_CONFIG[:url_param_name] => RUBYGEMS_FULL_URL }
      @shorten_rubylang_body = { SHORTEN_CONFIG[:url_param_name] => RUBYLANG_FULL_URL }
      stub_http_request(SHORTEN_METHOD, SHORTEN_CONFIG[:service_url]).
        with(:body => @shorten_rubygems_body).
        to_return(:body => RUBYGEMS_FIXTURE)
      stub_http_request(SHORTEN_METHOD, SHORTEN_CONFIG[:service_url]).
        with(:body => @shorten_rubylang_body).
        to_return(:body => RUBYLANG_FIXTURE)
      stub_http_request(:post, UPDATE_URL).
        with(:body => BODY_WITH_SHORT_URLS).
        to_return(:body => UPDATE_FIXTURE_WITH_URLS)
      at_snapshot do
        @output = start_cli %W{--no-colors update #{STATUS_WITH_FULL_URLS}}, %w{y}
      end
    end

    it "shortens the URLs in the status before sending it" do
      assert_requested(SHORTEN_METHOD, SHORTEN_CONFIG[:service_url], :body => @shorten_rubygems_body)
      assert_requested(SHORTEN_METHOD, SHORTEN_CONFIG[:service_url], :body => @shorten_rubylang_body)
      @output[1].must_equal STATUS_WITH_SHORT_URLS
      @output[5].must_equal "#{USER}, 9 hours ago:"
      @output[6].must_equal STATUS_WITH_SHORT_URLS
    end
  end

  describe "disable URL shortening for status updates" do
    before do
      stub_http_request(:post, UPDATE_URL).
        with(:body => BODY_WITH_SHORT_URLS).
        to_return(:body => UPDATE_FIXTURE_WITH_URLS)
      at_snapshot do
        @output = start_cli %W{--no-colors --no-url-shorten update #{STATUS_WITH_SHORT_URLS}}, %w{y}
      end
    end

    it "passes URLs as is in the status" do
      @output[1].must_equal STATUS_WITH_SHORT_URLS
      @output[5].must_equal "#{USER}, 9 hours ago:"
      @output[6].must_equal STATUS_WITH_SHORT_URLS
    end
  end
end

end
