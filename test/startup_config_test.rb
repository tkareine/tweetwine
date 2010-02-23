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

      should "allow passing default options" do
        opts = {:opt => "foo"}
        config = StartupConfig.new([:cmd_a], :cmd_a, opts)
        assert_equal opts, config.options
      end
    end

    context "at runtime" do
      setup do
        @config = StartupConfig.new([:default_action, :another_action], :default_action, {:defopt => 42})
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

      context "when given cmdline args and no config file" do
        setup do
          @cmd_args = %w{--opt bar --another_opt baz another_action left overs}
          @config.parse(@cmd_args) do |args|
            args.slice!(0..3)
            {:defopt => 56, :nopt => "baz"}
          end
        end

        should "have the parsed option defined" do
          assert_equal "baz", @config.options[:nopt]
        end

        should "override the default value for the option given as a cmdline arg" do
          assert_equal 56, @config.options[:defopt]
        end

        should "parse cmdline args before the command" do
          assert_equal({:defopt => 56, :nopt => "baz"}, @config.options)
        end

        should "identify the next argument after cmdline args as the command" do
          assert_equal :another_action, @config.command
        end

        should "leave remaining args to be consumed by the command" do
          assert_equal %w{left overs}, @cmd_args
        end
      end

      context "when given no cmdline args and a config file" do
        setup do
          @config.parse([], TEST_CONFIG_FILE)
        end

        should "have the parsed option defined" do
          assert_equal false, @config.options[:colors]
        end

        should "override the default value for the option given from the config file" do
          assert_equal 78, @config.options[:defopt]
        end
      end

      context "when given an option both as a cmdline option and in a config file" do
        setup do
          @config.parse(%w{--colors}, TEST_CONFIG_FILE) do |args|
            args.clear
            {:defopt => 56, :colors => true}
          end
        end

        should "the command line option should override the config file option" do
          assert_equal true, @config.options[:colors]
          assert_equal 56, @config.options[:defopt]
        end
      end
    end
  end
end

end
