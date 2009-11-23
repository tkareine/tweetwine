require "optparse"

module Tweetwine
  class CLI
    EXIT_HELP = 1
    EXIT_VERSION = 2
    EXIT_ERROR = 255

    def self.launch(args, exec_name, config_file, extra_opts = {})
      new(args, exec_name, config_file, extra_opts, &default_dependencies).execute(args)
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

    def initialize(args, exec_name, config_file, extra_opts = {}, &dependencies_blk)
      @global_option_parser = create_global_option_parser(exec_name)
      @config = StartupConfig.new(Client::COMMANDS + [:help], Client::DEFAULT_COMMAND, extra_opts)
      @config.parse(args, config_file, &@global_option_parser)
      @client = Client.new(dependencies_blk.call(@config.options), @config.options) if @config.command != :help
    end

    def show_help_command_and_exit(args)
      help_about_cmd = args.shift
      if help_about_cmd
        help_about_cmd = help_about_cmd.to_sym
        parse_command_options(help_about_cmd, ["-h"]) if Client::COMMANDS.include?(help_about_cmd)
      end
      @global_option_parser.call(["-h"])
    end

    def self.create_option_parser
      lambda do |args|
        parsed_options = {}
        begin
          parser = OptionParser.new do |opt|
            opt.on_tail("-h", "--help", "Show this help message and exit") {
              puts opt
              exit(EXIT_HELP)
            }
            schema = yield parsed_options
            opt.banner = schema[:help]
            schema[:opts].each do |opt_schema|
              opt.on(*option_schema_to_ary(opt_schema), &opt_schema[:action])
            end if schema[:opts]
          end.order!(args)
        rescue OptionParser::ParseError => e
          raise ArgumentError, e.message
        end
        parsed_options
      end
    end

    def self.option_schema_to_ary(opt_schema)
      [:short, :long, :type, :desc].inject([]) do |result, key|
        result << opt_schema[key] if opt_schema[key]
        result
      end
    end

    def create_global_option_parser(exec_name)
      self.class.create_option_parser do |parsed|
        {
          :help => \
"A simple but tasty Twitter agent for command line use, made for fun.

Usage: #{exec_name} [global_options...] [command] [command_options...]

  [command] is one of {#{Client::COMMANDS.join(", ")}},
  defaulting to #{Client::DEFAULT_COMMAND}.

  [global_options]:
",
          :opts => [
            {
              :short  => "-a",
              :long   => "--auth USERNAME:PASSWORD",
              :desc   => "Authentication",
              :action => lambda { |arg| parsed[:username], parsed[:password] = arg.split(":", 2) }
            },
            {
              :short  => "-c",
              :long   => "--colors",
              :desc   => "Colorize output with ANSI escape codes",
              :action => lambda { |arg| parsed[:colors] = true }
            },
            {
              :short  => "-n",
              :long   => "--num N",
              :type   => Integer,
              :desc   => "The number of statuses to fetch, defaults to #{Client::DEFAULT_NUM_STATUSES}",
              :action => lambda { |arg| parsed[:num_statuses] = arg }
            },
            {
              :long   => "--no-colors",
              :desc   => "Do not colorize output with ANSI escape codes",
              :action => lambda { |arg| parsed[:colors] = false }
            },
            {
              :long   => "--no-url-shorten",
              :desc   => "Do not shorten URLs for status update",
              :action => lambda { |arg| parsed[:shorten_urls] = { :enable => false } }
            },
            {
              :short  => "-p",
              :long   => "--page N",
              :type   => Integer,
              :desc   => "The page number of the statuses to fetch, defaults to #{Client::DEFAULT_PAGE_NUM}",
              :action => lambda { |arg| parsed[:page_num] = arg }
            },
            {
              :short  => "-v",
              :long   => "--version",
              :desc   => "Show version information and exit",
              :action => lambda do |arg|
                puts "#{exec_name} #{Tweetwine::VERSION}"
                exit(EXIT_VERSION)
              end
            }
          ]
        }
      end
    end

    def self.create_command_option_parser(command_name, schema)
      create_option_parser do |parsed|
        {
          :help => \
"#{command_name} [command_options...] #{schema[:help][:rest_args]}

#{schema[:help][:desc]}

  [command_options]:
",
          :opts => schema[:opts]
        }
      end
    end

    command_parser_schemas = {
      :followers => {
        :help => {
          :desc => \
"Show the followers of the authenticated user, together with the latest status
of each follower."
        }
      },
      :friends => {
        :help => {
          :desc => \
"Show the friends of the authenticated user, together with the latest status
of each friend."
        }
      },
      :home => {
        :help => {
          :desc => \
"Show the latest statuses of friends and own tweets (the public timeline of
the authenticated user)."
        }
      },
      :mentions => {
        :help => {
          :desc => \
"Show the latest statuses that mention the authenticated user."
        }
      },
      :search => {
        :help => {
          :rest_args  => "word_1 [word_2...]",
          :desc       => \
"Search the latest public statuses with one or more words."
        },
        :opts => [
          {
            :short  => "-a",
            :long   => "--and",
            :desc   => "All words must match",
            :action => lambda { |arg| parsed[:bin_op] = :and }
          },
          {
            :short  => "-o",
            :long   => "--or",
            :desc   => "Any word matches",
            :action => lambda { |arg| parsed[:bin_op] = :or }
          }
        ]
      },
      :update => {
        :help => {
          :rest_args  => "[status]",
          :desc       => \
"Send a status update, but confirm the action first before actually sending.
The status update can either be given as an argument or via STDIN if no
[status] is given."
        }
      },
      :user => {
        :help => {
          :rest_args  => "[username]",
          :desc       => \
"Show a specific user's latest statuses. The user is identified with [username]
argument; if the argument is absent, the authenticated user's statuses are
shown."
        }
      }
    }

    COMMAND_OPTION_PARSERS = Client::COMMANDS.inject({}) do |result, cmd|
      result[cmd] = create_command_option_parser(cmd, command_parser_schemas[cmd])
      result
    end

    def parse_command_options(command, args)
      COMMAND_OPTION_PARSERS[command].call(args)
    end
  end
end
