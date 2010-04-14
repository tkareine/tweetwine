# coding: utf-8

require "test_helper"

module Tweetwine

class CLITest < TweetwineTestCase
  context "A CLI, upon initialization" do
    should "disallow using #new to create a new instance" do
      assert_raise(NoMethodError) { CLI.new("-v", "test", "") {} }
    end
  end

  # Other unit tests are meaningless. See /example directory for tests
  # about the functionality of the application.
end

end
