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
      File.open(@file, 'w') { |io| YAML.dump(Util.stringify_hash_keys(to_file), io) }
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
        result[env_var_name.to_sym] = env_option unless Util.blank?(env_option)
        result
      end
    end

    def self.parse_config_file(config_file)
      options = File.open(config_file, 'r') { |io| YAML.load(io) }
      Util.symbolize_hash_keys(options)
    end
  end
end
