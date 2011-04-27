# coding: utf-8

require 'unit/helper'

module Tweetwine::Test::Unit

class OptionParserTest < TestCase
  before do
    @parser = OptionParser.new do |parser, options|
      parser.on '-c', '--colors',           'Enable colors.' do
        options[:colors] = true
      end
      parser.on '-u', '--username <user>',  'Specify user.' do |arg|
        options[:username] = arg
      end
    end
  end

  it "returns empty options if no options (no default values)" do
    options = @parser.parse %w{}
    assert options.empty?
  end

  it "returns only options that occurred (no default values)" do
    options = @parser.parse %w{-u jack}
    assert_equal({:username => 'jack'}, options)
  end

  it "returns copy of options after parsing" do
    options1 = @parser.parse %w{-u jack}
    options2 = @parser.parse %w{-c}
    assert_equal({:username => 'jack'}, options1)
    assert_equal({:colors   => true},   options2)
  end

  it "parses from beginning, removing recognized options" do
    args = %w{-u jack foo bar}
    options = @parser.parse args
    assert_equal(%w{foo bar}, args)
  end

  it "parses from beginning, leaving option-like arguments after non-option arguments in place" do
    args = %w{-c foo -u jack bar}
    options = @parser.parse args
    assert_equal(%w{foo -u jack bar}, args)
    assert_equal({:colors => true}, options)
  end

  it "raises exception upon unrecognized option" do
    assert_raises(CommandLineError) { @parser.parse %w{-d} }
  end

  it "describes option syntax" do
    description = @parser.help.split("\n")
    assert_match(/\A\s+\-c, \-\-colors\s+Enable colors.\z/,         description[0])
    assert_match(/\A\s+\-u, \-\-username <user>\s+Specify user.\z/, description[1])
  end
end

end
