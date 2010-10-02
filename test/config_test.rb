# coding: utf-8

require "test_helper"

require "fileutils"
require "tempfile"

module Tweetwine

class ConfigTest < UnitTestCase
  CONFIG_FILE = Helper.fixture_file("test_config.yaml")

  context "when given command line arguments, no environment variables, no config file" do
    setup do
      @args = %w{--opt cmd_opt --defopt cmd_defopt left overs}
      default_config = {:defopt => 'defopt'}
      @config = Config.read(@args, [], nil, default_config) do |args|
        args.slice!(0..3)
        {:opt => 'cmd_opt', :defopt => 'cmd_defopt'}
      end
    end

    should "have option defined from command line" do
      assert_equal 'cmd_opt', @config[:opt]
    end

    should "override option default value from command line" do
      assert_equal 'cmd_defopt', @config[:defopt]
    end

    should "leave remaining command line arguments unconsumed" do
      assert_equal %w{left overs}, @args
    end
  end

  context "when given command line arguments, environment variables, no config file" do
    setup do
      ENV['opt']    = 'env_opt'
      ENV['defopt'] = 'env_defopt'
      ENV['envopt'] = 'env_envopt'
      @args = %w{--opt cmd_opt}
      default_config = {:defopt => 'defopt'}
      @config = Config.read(@args, [:defopt, :envopt, :opt], nil, default_config) do |args|
        args.slice!(0..1)
        {:opt => 'cmd_opt'}
      end
    end

    teardown do
      ENV['opt']    = nil
      ENV['defopt'] = nil
      ENV['envopt'] = nil
    end

    should "have option defined from environment variable" do
      assert_equal 'env_envopt', @config[:envopt]
    end

    should "override option value from command line over environment variable" do
      assert_equal 'cmd_opt', @config[:opt]
    end

    should "override option default value from environment variable" do
      assert_equal 'env_defopt', @config[:defopt]
    end
  end

  context "when given command line arguments, no environment variables, config file" do
    setup do
      @args = %w{--opt cmd_opt}
      default_config = {:defopt => 'defopt'}
      @config = Config.read(@args, [], CONFIG_FILE, default_config) do |args|
        args.slice!(0..1)
        {:opt => 'cmd_opt'}
      end
    end

    should "have option defined from config file" do
      assert_equal 'file_fileopt', @config[:fileopt]
    end

    should "override option value from command line over config file" do
      assert_equal 'cmd_opt', @config[:opt]
    end

    should "override option default value from config file" do
      assert_equal 'file_defopt', @config[:defopt]
    end
  end

  context "when given command line arguments, environment variables, config file" do
    setup do
      @args = %w{--opt2 cmd_opt2}
      ENV['opt']  = 'env_opt'
      ENV['opt2'] = 'env_opt2'
      @config = Config.read(@args, [:opt, :opt2], CONFIG_FILE) do |args|
        args.slice!(0..2)
        {:opt2 => 'cmd_opt2'}
      end
    end

    teardown do
      ENV['opt']  = nil
      ENV['opt2'] = nil
    end

    should "override option value from environment variable over config file" do
      assert_equal 'env_opt', @config[:opt]
    end

    should "override option value from command line over environment variable and config file" do
      assert_equal 'cmd_opt2', @config[:opt2]
    end
  end

  context "when handling command line arguments without parser" do
    setup do
      ENV['opt'] = 'env_opt'
      @args = %w{--opt cmd_opt --defopt cmd_defopt}
      default_config = {:defopt => 'defopt'}
      @config = Config.read(@args, [:opt], CONFIG_FILE, default_config)
    end

    teardown do
      ENV['opt'] = nil
    end

    should "ignore command line arguments, using environment variables and config file for options if available" do
      assert_equal 'env_opt', @config[:opt]
      assert_equal 'file_defopt', @config[:defopt]
    end
  end

  context "when handling environment variables" do
    setup do
      ENV['visible'] = 'env_visible'
      ENV['hidden']  = 'env_hidden'
      ENV['empty']   = ''
      @config = Config.read([], [:visible, :empty])
    end

    teardown do
      ENV['visible'] = nil
      ENV['hidden'] = nil
      ENV['empty'] = nil
    end

    should "consider only specified environment variables that are nonempty" do
      assert_equal 'env_visible', @config[:visible]
    end

    should "not consider empty environment variables" do
      assert_equal nil, @config[:empty]
    end

    should "not consider unspecified environment variables" do
      assert_equal nil, @config[:hidden]
    end
  end

  context "when handling the config file" do
    setup do
      @tmp_dir = Dir.mktmpdir
    end

    teardown do
      FileUtils.remove_entry_secure @tmp_dir
    end

    context "when config file does not exist" do
      setup do
        @file = @tmp_dir + '/no_such_file'
        @config = Config.read([], [], @file)
      end

      should "ignore the config file" do
        assert @config.keys.empty?
      end

      should "save the config file as a new file" do
        @config[:foo] = 'bar'
        @config.save
        assert_equal({:foo => 'bar'}, YAML.load_file(@file))
      end
    end

    context "when updating the config file" do
      setup do
        @file = @tmp_dir + '/config.yaml'
        FileUtils.cp CONFIG_FILE, @file
        @config = Config.read([], [], @file)
      end

      should "save the config file, overwriting the previous" do
        @config[:fileopt] = 'bar'
        @config.save
        expected = {
          :opt      => 'file_opt',
          :fileopt  => 'bar',
          :defopt   => 'file_defopt'
        }
        assert_equal expected, YAML.load_file(@file)
      end

      should "exclude saving selected keys" do
        @config.exclude_on_save :fileopt, :defopt
        @config[:fileopt] = 'bar'
        @config.save
        expected = { :opt => 'file_opt' }
        assert_equal expected, YAML.load_file(@file)
      end
    end
  end
end

end
