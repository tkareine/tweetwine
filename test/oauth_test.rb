# coding: utf-8

require "test_helper"
require "fixture/oauth"
require "net/http"

module Tweetwine::Test

class OAuthTest < UnitTestCase
  include OAuthFixture

  setup do
    mock_http
    mock_ui
    @oauth = OAuth.new
  end

  should "authorize with PIN code so that request can be signed" do
    expect_complete_oauth_dance
    @oauth.authorize
    connection, request = *fake_http_connection_and_request
    @oauth.request_signer.call(connection, request)
    assert_match(/^OAuth /, request['Authorization'])
    assert_match(/oauth_token="#{ACCESS_TOKEN_KEY}"/, request['Authorization'])
  end

  should "raise AuthorizationError if OAuth dance fails due to HTTP 4xx response" do
    @http.expects(:post).
        with(REQUEST_TOKEN_URL).
        raises(HttpError.new(401, 'Unauthorized'))
    assert_raise(AuthorizationError) { @oauth.authorize }
  end

  should "pass other exceptions than due to HTTP 4xx responses through" do
    @http.expects(:post).
        with(REQUEST_TOKEN_URL).
        raises(HttpError.new(503, 'Service Unavailable'))
    assert_raise(HttpError) { @oauth.authorize }
  end

  context "when access token is known" do
    setup do
      @oauth = OAuth.new(Obfuscate.write("#{ACCESS_TOKEN_KEY}:2"))
    end

    should "sign request with it" do
      connection, request = *fake_http_connection_and_request
      @oauth.request_signer.call(connection, request)
      assert_match(/^OAuth /, request['Authorization'])
      assert_match(/oauth_token="#{ACCESS_TOKEN_KEY}"/, request['Authorization'])
    end
  end

  private

  def expect_complete_oauth_dance
    @http.expects(:post).
        with(REQUEST_TOKEN_URL).
        returns(REQUEST_TOKEN_RESPONSE)
    @ui.expects(:info).
        with("Please authorize: #{AUTHORIZE_URL}")
    @ui.expects(:prompt).
        with('Enter PIN').
        returns(PIN)
    @http.expects(:post).
        with(ACCESS_TOKEN_URL).
        returns(ACCESS_TOKEN_RESPONSE)
  end

  def fake_http_connection_and_request
    connection = stub(:address => 'api.twitter.com', :port => 443)
    request = Net::HTTP::Post.new('1/statuses/home_timeline.json')
    [connection, request]
  end
end

end
