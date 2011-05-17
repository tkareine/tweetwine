# coding: utf-8

require "set"
require "yaml"

module Tweetwine
  class Config
    def self.read(args = [], default_config = {}, &cmd_option_parser)
      new parse_options(args, default_config, &cmd_option_parser)
    end

    def [](key)
      @options[key]
    end

    def []=(key, value)
      @options[key] = value
    end

    def keys
      @options.keys
    end

    def save
      raise "No config file specified" unless @file
      to_file = @options.reject { |key, _| @excludes.include? key }
      should_set_file_access_to_user_only = !File.exist?(@file)
      File.open(@file, 'w') do |io|
        io.chmod(0600) if should_set_file_access_to_user_only
        YAML.dump(Support.stringify_hash_keys(to_file), io)
      end
    end

    private

    def initialize(options)
      @options = options
      @file = options[:config_file]
      @excludes = Set.new(options[:excludes] || []).merge([:config_file, :env_lookouts, :excludes])
    end

    def self.parse_options(args, default_config, &cmd_option_parser)
      env_lookouts = default_config[:env_lookouts]
      cmd_options = if cmd_option_parser then cmd_option_parser.call(args) else {} end
      env_options = if env_lookouts then parse_env_vars(env_lookouts) else {} end
      launch_options = env_options.merge(cmd_options)
      config_file = launch_options[:config_file] || default_config[:config_file]
      file_options = if config_file && File.file?(config_file) then parse_config_file(config_file) else {} end
      default_config.merge(file_options.merge(launch_options))
    end

    def self.parse_env_vars(env_lookouts)
      env_lookouts.inject({}) do |result, env_var_name|
        env_option = ENV[env_var_name.to_s]
        result[env_var_name.to_sym] = env_option if Support.present?(env_option)
        result
      end
    end

    def self.parse_config_file(config_file)
      config = YAML.load_file config_file
      raise ConfigError, "invalid config file; it must be a mapping style YAML document: #{config_file}" unless config.is_a? Hash
      Support.symbolize_hash_keys(config)
    end
  end
end
