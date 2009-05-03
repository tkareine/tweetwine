module Tweetwine
  class StartupConfig
    attr_reader :options, :command, :args, :supported_commands

    def initialize(supported_commands)
      @supported_commands = supported_commands.to_a
      raise ArgumentError, "Must give at least one supported command" if @supported_commands.empty?
      @options = {}
      @command = @supported_commands.first
      @args = []
    end

    def parse(args = [], config_file = nil, &cmd_parser)
      options = parse_options(args, config_file, &cmd_parser)
      command = if args.empty? then @supported_commands.first else args.shift.to_sym end
      raise ArgumentError, "Unknown command." unless @supported_commands.include? command
      @options, @command, @args = options, command, args
      self
    end

    private

    def parse_options(args, config_file, &cmd_parser)
      cmd_options = if cmd_parser then parse_cmdline_args(args, &cmd_parser) else {} end
      config_options = if config_file && File.exists?(config_file) then parse_config_file(config_file) else {} end
      config_options.merge(cmd_options)
    end

    def parse_cmdline_args(args, &cmd_parser)
      cmd_parser.call(args)
    end

    def parse_config_file(config_file)
      options = YAML.load(File.read(config_file))
      options.inject({}) do |result, pair|
        result[pair.first.to_sym] = pair.last
        result
      end
    end
  end
end
