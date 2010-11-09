# coding: utf-8

require "test_helper"

require "fileutils"
require "tempfile"
require "yaml"

module Tweetwine::Test

class ConfigTest < UnitTestCase
  CONFIG_FILE = Helper.fixture_file("test_config.yaml")

  context "when given command line arguments, no environment variables, no config file" do
    setup do
      @args = %w{--opt cmd_opt --defopt cmd_defopt left overs}
      default_config = {:defopt => 'defopt'}
      @config = Config.read(@args, default_config) do |args|
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
      default_config = {:defopt => 'defopt', :env_lookouts => [:defopt, :envopt, :opt]}
      @config = Config.read(@args, default_config) do |args|
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
      default_config = {:config_file => CONFIG_FILE, :defopt => 'defopt'}
      @config = Config.read(@args, default_config) do |args|
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
      @config = Config.read(@args, :config_file => CONFIG_FILE, :env_lookouts => [:opt, :opt2]) do |args|
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
      default_config = {:config_file => CONFIG_FILE, :defopt => 'defopt', :env_lookouts => [:opt]}
      @config = Config.read(@args, default_config)
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
      @config = Config.read([], :env_lookouts => [:visible, :empty])
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
    should "allow specifying configuration file from command line arguments" do
      @args = ['-f', CONFIG_FILE]
      @config = Config.read(@args, {}) do
        @args.slice!(0..1)
        {:config_file => CONFIG_FILE}
      end
      assert_equal %w{config_file defopt fileopt opt}, @config.keys.map { |k| k.to_s }.sort
      assert_equal 'file_defopt', @config[:defopt]
    end

    should "raise exception when trying to save and no config file is specified" do
      @config = Config.read()
      assert_raise(RuntimeError) { @config.save }
    end

    context "when config file does not exist" do
      setup do
        @tmp_dir = Dir.mktmpdir
        @file = @tmp_dir + '/.tweetwine'
        @excludes = [:secret]
        @default_config = {:config_file => @file, :env_lookouts => [:envopt], :excludes => @excludes}
        @config = Config.read([], @default_config)
        @expected_config = {'new_opt' => 'to_file'}
      end

      teardown do
        FileUtils.remove_entry_secure @tmp_dir
      end

      should "ignore nonexisting config file for initial read" do
        assert_equal @config.keys, @default_config.keys
      end

      should "save config to the file, implicitly without config file, env lookouts, and excludes set itself" do
        @config[:new_opt] = 'to_file'
        @config.save
        stored = YAML.load_file @file
        assert_equal(@expected_config, stored)
      end

      should "save config to the file, explicitly without excluded entries" do
        @config[@excludes.first] = 'password'
        @config[:new_opt] = 'to_file'
        @config.save
        stored = YAML.load_file @file
        assert_equal(@expected_config, stored)
      end

      should "modifying exclusions after initial read has no effect on config file location and exclusions" do
        @config[:config_file] = @tmp_dir + '/.tweetwine.another'
        @config[:excludes] << :new_opt
        @config[:new_opt] = 'to_file'
        @config.save
        stored = YAML.load_file @file
        assert_equal(@expected_config, stored)
      end

      should "set config file permissions accessible only to the user when saving" do
        @config.save
        assert_equal 0600, file_mode(@file)
      end

      context "when config file exists" do
        setup do
          FileUtils.touch @file
          @original_mode = 0644
          File.chmod @original_mode, @file
        end

        should "not set config file permissions when saving" do
          @config.save
          assert_equal @original_mode, file_mode(@file)
        end
      end
    end
  end
end

end
