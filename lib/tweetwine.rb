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
  require "tweetwine/#{f}"
end
