require "yaml"

module Tweetwine
  class StartupConfig
    attr_reader :options, :command

    def initialize(supported_commands, default_command)
      raise ArgumentError, "Must give at least one supported command" if supported_commands.empty?
      raise ArgumentError, "Default command is not a supported command" unless supported_commands.include? default_command
      @supported_commands, @default_command = supported_commands, default_command
      @options, @command = {}, nil
    end

    def parse(args = [], config_file = nil, &cmd_option_parser)
      options = parse_options(args, config_file, &cmd_option_parser)
      command = if args.empty? then @default_command else args.shift.to_sym end
      raise ArgumentError, "Unknown command" unless @supported_commands.include? command
      @options, @command = options, command, args
      self
    end

    private

    def parse_options(args, config_file, &cmd_option_parser)
      cmd_options = if cmd_option_parser then parse_cmdline_args(args, &cmd_option_parser) else {} end
      config_options = if config_file && File.exists?(config_file) then parse_config_file(config_file) else {} end
      config_options.merge(cmd_options)
    end

    def parse_cmdline_args(args, &cmd_option_parser)
      cmd_option_parser.call(args)
    end

    def parse_config_file(config_file)
      options = YAML.load(File.read(config_file))
      Util.symbolize_hash_keys(options)
    end
  end
end
