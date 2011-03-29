# coding: utf-8

require 'unit/helper'
require 'stringio'

module Tweetwine::Test

# See +example+ directory for integration tests.
class CLITest < UnitTestCase
  context "for initialization" do
    should "disallow using #new to create a new instance" do
      assert_raise(NoMethodError) { CLI.new }
    end

    should "allow defining same option multiple times, last value winning" do
      winning_option_value = 'second'
      start_cli %W{-f first -f #{winning_option_value} -v}
      assert_equal winning_option_value, CLI.config[:config_file]
    end
  end

  private

  def start_cli(args)
    output = StringIO.new
    CLI.start(args, { :out => output })
    output.string.split("\n")
  end
end

end
