require "test_helper"

module Tweetwine

class StartupConfigTest < Test::Unit::TestCase
  TEST_CONFIG_FILE = File.dirname(__FILE__) << "/fixtures/test_config.yaml"

  context "A StartupConfig instance" do
    context "upon initialization" do
      should "require at least one supported command" do
        assert_raise(ArgumentError) { StartupConfig.new([]) }
        assert_nothing_raised { StartupConfig.new([:cmd], :cmd) }
      end

      should "require the default command to be a supported command" do
        assert_raise(ArgumentError) { StartupConfig.new([:cmd_a], :cmd_b) }
        assert_nothing_raised { StartupConfig.new([:cmd_a], :cmd_a) }
      end
    end

    context "at runtime" do
      setup do
        @config = StartupConfig.new([:default_action, :another_action], :default_action)
      end

      should "use the default command when given no command as a cmdline argument" do
        @config.parse
        assert_equal :default_action, @config.command
      end

      should "pass supported commands" do
        @config.parse(%w{default_action}) { |args| {} }
        assert_equal :default_action, @config.command

        @config.parse(%w{another_action}) { |args| {} }
        assert_equal :another_action, @config.command
      end

      should "raise ArgumentError if given command is not supported" do
        assert_raise(ArgumentError) do
          @config.parse(%w{unknown_action}) { |args| {} }
        end
      end

      should "allow parsing cmdline args before the command" do
        cmd_args = %w{--opt foo another_action left overs}
        @config.parse(cmd_args) do |args|
           args.slice!(0..1)
           {:opt => "foo"}
        end
        assert_equal({:opt => "foo"}, @config.options)
        assert_equal :another_action, @config.command
        assert_equal %w{left overs},  cmd_args
      end

      context "when given no cmdline args and a config file" do
        setup do
          @config.parse([], TEST_CONFIG_FILE)
        end

        should "have the parsed option defined" do
          assert_equal false, @config.options[:colorize]
        end
      end

      context "when given cmdline args and no config file" do
        setup do
          @config.parse(%w{--opt foo}) do |args|
            args.clear
            {:opt => "foo"}
          end
        end

        should "have the parsed option defined" do
          assert_equal "foo", @config.options[:opt]
        end
      end

      context "when given an option both as a cmdline option and in a config file" do
        setup do
          @config.parse(%w{--colorize}, TEST_CONFIG_FILE) do |args|
            args.clear
            {:colorize => true}
          end
        end

        should "the command line option should override the config file option" do
          assert_equal true, @config.options[:colorize]
        end

        should "have nil for an undefined option" do
          assert_nil @config.options[:num_statuses]
        end
      end
    end
  end
end

end
