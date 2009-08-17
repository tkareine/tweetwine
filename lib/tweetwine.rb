%w{
  meta
  util
  options
  startup_config
  io
  rest_client_wrapper
  url_shortener
  client
}.each do |f|
  require File.dirname(__FILE__) << "/tweetwine/#{f}"
end
