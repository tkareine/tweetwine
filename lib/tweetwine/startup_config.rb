require "yaml"

module Tweetwine
  class StartupConfig
    attr_reader :options, :command

    def initialize(supported_commands, default_command, default_opts = {})
      raise ArgumentError, "Must give at least one supported command" if supported_commands.empty?
      raise ArgumentError, "Default command is not a supported command" unless supported_commands.include? default_command
      @supported_commands, @default_command = supported_commands, default_command
      @options, @command = default_opts, nil
    end

    def parse(args = [], config_file = nil, env_lookouts = [], &cmd_option_parser)
      options = @options.merge(parse_options(args, config_file, env_lookouts, &cmd_option_parser))
      command = if args.empty? then @default_command else args.shift.to_sym end
      raise ArgumentError, "Unknown command" unless @supported_commands.include? command
      @options, @command = options, command
      self
    end

    private

    def parse_options(args, config_file, env_lookouts, &cmd_option_parser)
      cmd_options = if cmd_option_parser then parse_cmdline_args(args, &cmd_option_parser) else {} end
      config_options = if config_file && File.exists?(config_file) then parse_config_file(config_file) else {} end
      env_options = if env_lookouts then parse_env_vars(env_lookouts) else {} end
      env_options.merge(config_options.merge(cmd_options))
    end

    def parse_cmdline_args(args, &cmd_option_parser)
      cmd_option_parser.call(args)
    end

    def parse_config_file(config_file)
      options = YAML.load(File.read(config_file))
      Util.symbolize_hash_keys(options)
    end

    def parse_env_vars(env_lookouts)
      env_lookouts.inject({}) do |result, env_var_name|
        env_option = ENV[env_var_name.to_s]
        result[env_var_name.to_sym] = env_option if env_option && !env_option.empty?
        result
      end
    end
  end
end
