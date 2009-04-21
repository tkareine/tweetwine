require "rubygems"
require File.dirname(__FILE__) << "/../lib/tweetwine"
require "test/unit"
require "shoulda"
require "mocha"

Mocha::Configuration.prevent(:stubbing_non_existent_method)
