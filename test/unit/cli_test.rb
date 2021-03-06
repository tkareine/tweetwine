# coding: utf-8

require 'support/unit_test_case'
require 'stringio'

module Tweetwine::Test::Unit

# See `test/integration` directory for integration tests.
class CLITest < TestCase
  describe "for initialization" do
    it "disallows using #new to create a new instance" do
      assert_raises(NoMethodError) { Tweetwine::CLI.new }
    end

    it "allows defining same option multiple times, last value winning" do
      winning_option_value = 'second'
      start_cli %W{-f first -f #{winning_option_value} -v}
      assert_equal winning_option_value, Tweetwine::CLI.config[:config_file]
    end
  end

  private

  def start_cli(args)
    output = StringIO.new
    Tweetwine::CLI.start(args, { :out => output })
    output.string.split("\n")
  end
end

end
