# coding: utf-8

require "test_helper"

module Tweetwine

class CLITest < UnitTestCase
  context "for initialization" do
    should "disallow using #new to create a new instance" do
      assert_raise(NoMethodError) { CLI.new }
    end
  end

  # See +example+ directory for integration tests.
end

end
