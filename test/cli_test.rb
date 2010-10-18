# coding: utf-8

require "test_helper"

module Tweetwine::Test

# See +example+ directory for integration tests.
class CLITest < UnitTestCase
  context "for initialization" do
    should "disallow using #new to create a new instance" do
      assert_raise(NoMethodError) { CLI.new }
    end
  end
end

end
