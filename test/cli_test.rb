require "test_helper"

module Tweetwine

class CLITest < Test::Unit::TestCase
  context "A CLI, upon initialization" do
    should "disallow using #new to create a new instance" do
      assert_raise(NoMethodError) { CLI.new("-v", "", "") }
    end
  end

  # Other unit tests are meaningless. See example/ directory for functional
  # tests.
end

end
