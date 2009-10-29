require "optparse"

module Tweetwine
  class CLI
    EXIT_HELP = 1
    EXIT_VERSION = 2
    EXIT_ERROR = 255

    def self.launch(args, exec_name, config_file)
      new(args, exec_name, config_file, &default_dependencies).execute(args)
    rescue ArgumentError, HttpError => e
      puts "Error: #{e.message}"
      exit(EXIT_ERROR)
    end

    def execute(args)
      if @config.command != :help
        cmd_options = parse_command_options(@config.command, args)
        @client.send(@config.command, args, cmd_options)
      else
        show_help_command_and_exit(args)
      end
    end

    private

    def self.default_dependencies
      lambda do |options|
        io = Tweetwine::IO.new(options)
        http_client = RetryingHttp::Client.new(io)
        url_shortener = lambda { |opts| UrlShortener.new(http_client, opts) }
        Client::Dependencies.new(io, http_client, url_shortener)
      end
    end

    def initialize(args, exec_name, config_file, &dependencies_blk)
      @global_option_parser = create_global_option_parser(exec_name)
      @config = StartupConfig.new(Client::COMMANDS + [:help], Client::DEFAULT_COMMAND)
      @config.parse(args, config_file, &@global_option_parser)
      @client = Client.new(dependencies_blk.call(@config.options), @config.options) if @config.command != :help
    end

    def parse_command_options(command, args)
      COMMAND_OPTION_PARSERS[command.to_sym].call(args)
    end

    def show_help_command_and_exit(args)
      help_about_cmd = args.shift
      if help_about_cmd
        parse_command_options(help_about_cmd, ["-h"])
      else
        @global_option_parser.call(["-h"])
      end
    end

    def self.create_option_parser(&schema_blk)
      lambda do |args|
        parsed_options = {}
        begin
          parser = OptionParser.new do |opt|
            opt.on_tail("-h", "--help", "Show this help message and exit") {
              puts opt
              exit(EXIT_HELP)
            }
            schema_blk.call(opt, parsed_options)
          end.order!(args)
        rescue OptionParser::ParseError => e
          raise ArgumentError, e.message
        end
        parsed_options
      end
    end

    def create_global_option_parser(exec_name)
      self.class.create_option_parser do |opt, parsed|
        opt.banner =<<-EOS
A simple but tasty Twitter agent for command line use, made for fun.

Usage: #{exec_name} [global_options...] [command] [command_options...]

  [command] is one of {#{Client::COMMANDS.join(", ")}},
  defaulting to #{Client::DEFAULT_COMMAND}.

  [global_options]:

        EOS

        opt.on("-a", "--auth USERNAME:PASSWORD", "Authentication") do |arg|
          parsed[:username], parsed[:password] = arg.split(":", 2)
        end

        opt.on("-c", "--colorize", "Colorize output with ANSI escape codes") do
          parsed[:colorize] = true
        end

        opt.on("-n", "--num N", Integer, "The number of statuses to fetch, defaults to #{Client::DEFAULT_NUM_STATUSES}") do |arg|
          parsed[:num_statuses] = arg
        end

        opt.on("--no-colorize", "Do not colorize output with ANSI escape codes") do
          parsed[:colorize] = false
        end

        opt.on("--no-url-shorten", "Do not shorten URLs for status update") do
          parsed[:shorten_urls] = { :enable => false }
        end

        opt.on("-p", "--page N", Integer, "The page number of the statuses to fetch, defaults to #{Client::DEFAULT_PAGE_NUM}") do |arg|
          parsed[:page_num] = arg
        end

        opt.on("-v", "--version", "Show version information and exit") do
          puts "#{exec_name} #{Tweetwine::VERSION}"
          exit(EXIT_VERSION)
        end
      end
    end

    def self.create_home_option_parser
      create_option_parser do |opt, parsed|
        opt.banner =<<-EOS
home [command_options...]

Show the latest statuses of friends and own tweets (the public timeline of
the authenticated user).

  [command_options]:

        EOS
      end
    end

    def self.create_mentions_option_parser
      create_option_parser do |opt, parsed|
        opt.banner =<<-EOS
mentions [command_options...]

Show the latest statuses that mention the authenticated user.

  [command_options]:

        EOS
      end
    end

    def self.create_user_option_parser
      create_option_parser do |opt, parsed|
        opt.banner =<<-EOS
user [command_options...] [username]

Show a specific user's latest statuses. The user is identified with [username]
argument; if the argument is absent [username] is the authenticated user
itself.

  [command_options]:

        EOS
      end
    end

    def self.create_update_option_parser
      create_option_parser do |opt, parsed|
        opt.banner =<<-EOS
update [command_options...] [status...]

Send a status update, but confirm the action first before actually sending.
The status update can either be given as an argument or via STDIN if no
[status] is given.

  [command_options]:

        EOS
      end
    end

    def self.create_friends_option_parser
      create_option_parser do |opt, parsed|
        opt.banner =<<-EOS
friends [command_options...]

Show the friends of the authenticated user, together with the latest status
of each friend.

  [command_options]:

        EOS
      end
    end

    def self.create_followers_option_parser
      create_option_parser do |opt, parsed|
        opt.banner =<<-EOS
followers [command_options...]

Show the followers of the authenticated user, together with the latest status
of each follower.

  [command_options]:

        EOS
      end
    end

    def self.create_search_option_parser
      create_option_parser do |opt, parsed|
        opt.banner =<<-EOS
search [command_options...] term_1 [term_2...]

Search the latest worldwide statuses with one or more terms.

  [command_options]:

        EOS

        opt.on("-a", "--and", "All words must match") { parsed[:and] = true }

        opt.on("-o", "--or", "Any word can match") { parsed[:or] = true }
      end
    end

    COMMAND_OPTION_PARSERS = Client::COMMANDS.inject({}) do |result, cmd|
      result[cmd] = lambda { |args| send(:"create_#{cmd}_option_parser").call(args) }
      result
    end
  end
end
