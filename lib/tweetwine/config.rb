# coding: utf-8

require "yaml"

module Tweetwine
  class Config
    def self.read(args = [], default_config = {}, &cmd_option_parser)
      new parse_options(args, default_config, &cmd_option_parser)
    end

    def [](key)
      @options[key]
    end

    def keys
      @options.keys
    end

    private

    def initialize(options)
      @options = options
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
        result[env_var_name.to_sym] = env_option unless Util.blank?(env_option)
        result
      end
    end

    def self.parse_config_file(config_file)
      options = YAML.load_file(config_file)
      Util.symbolize_hash_keys(options)
    end
  end
end
