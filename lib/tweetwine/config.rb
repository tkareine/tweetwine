# coding: utf-8

require "yaml"

module Tweetwine
  class Config
    def self.read(args = [], env_lookouts = nil, config_file = nil, default_config = {}, &cmd_option_parser)
      options = parse_options(args, env_lookouts, config_file, default_config, &cmd_option_parser)
      new(config_file, options)
    end

    def [](key)
      @options[key]
    end

    def keys
      @options.keys
    end

    private

    def initialize(file, options)
      @file = file
      @options = options
    end

    def self.parse_options(args, env_lookouts, config_file, default_config, &cmd_option_parser)
      cmd_options  = if cmd_option_parser then cmd_option_parser.call(args) else {} end
      env_options  = if env_lookouts then parse_env_vars(env_lookouts) else {} end
      file_options = if config_file && File.exist?(config_file) then parse_config_file(config_file) else {} end
      default_config.merge(file_options.merge(env_options.merge(cmd_options)))
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
