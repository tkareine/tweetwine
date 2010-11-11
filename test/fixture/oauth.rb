# coding: utf-8

module Tweetwine::Test

module Fixture
  module OAuth
    METHOD = :post
    REQUEST_TOKEN_KEY = 'ManManManManManManManManManManManManManM'
    REQUEST_TOKEN_SECRET = '3x3x3x3x3x3x3x3x3x3x3x3x3x3x3x3x3x3x3x3x3'
    REQUEST_TOKEN_RESPONSE = "oauth_token=#{REQUEST_TOKEN_KEY}&oauth_token_secret=#{REQUEST_TOKEN_SECRET}&oauth_callback_confirmed=true"
    REQUEST_TOKEN_URL = 'https://api.twitter.com/oauth/request_token'
    ACCESS_TOKEN_KEY = '111111111-XyzXyzXyzXyzXyzXyzXyzXyzXyzXyzXyzXyzXyzX'
    ACCESS_TOKEN_SECRET = '4x4x4x4x4x4x4x4x4x4x4x4x4x4x4x4x4x4x4x4x4x'
    ACCESS_TOKEN_RESPONSE = "oauth_token=#{ACCESS_TOKEN_KEY}&oauth_token_secret=#{ACCESS_TOKEN_SECRET}&user_id=42&screen_name=fooman"
    ACCESS_TOKEN_URL = 'https://api.twitter.com/oauth/access_token'
    AUTHORIZE_URL = "https://api.twitter.com/oauth/authorize?oauth_token=#{REQUEST_TOKEN_KEY}"
    PIN = '12345678'
  end
end

end
