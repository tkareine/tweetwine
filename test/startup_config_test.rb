require File.dirname(__FILE__) << "/test_helper"

module Tweetwine

class StartupConfigTest < Test::Unit::TestCase
  TEST_CONFIG_FILE = File.dirname(__FILE__) << "/test_config.yaml"

  context "To initialize a StartupConfig" do
    should "require at least one supported command" do
      assert_raise(ArgumentError) { StartupConfig.new([]) }
      assert_nothing_raised { StartupConfig.new([:default_action]) }
    end
  end

  context "An initialized StartupConfig" do
    setup do
      @config = StartupConfig.new([:default_action, :another_action])
    end

    should "use the first supported command as a default command when given no command as a cmdline argument" do
      @config.parse
      assert_equal :default_action, @config.command
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
