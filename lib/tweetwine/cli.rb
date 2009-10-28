require "optparse"

module Tweetwine
  class CLI
    EXIT_HELP = 1
    EXIT_VERSION = 2
    EXIT_ERROR = -1

    def self.launch(args, exec_name, config_file)
      new(args, exec_name, config_file)
    end

    private

    private_class_method :new

    def initialize(args, exec_name, config_file)
      config = StartupConfig.new(Client::COMMANDS, Client::DEFAULT_COMMAND)
      config.parse(args, config_file, &create_global_option_parser(exec_name))
      cmd_options = parse_command_options(config.command, args)
      client = Client.new(create_dependencies(config.options), config.options)
      client.send(config.command, args, cmd_options)
    rescue ArgumentError, HttpError => e
      puts "Error: #{e.message}"
      exit(EXIT_ERROR)
    end

    def create_dependencies(options)
      io = Tweetwine::IO.new(options)
      http_client = RetryingHttp::Client.new(io)
      url_shortener = lambda { |opts| UrlShortener.new(http_client, opts) }
      Client::Dependencies.new(io, http_client, url_shortener)
    end

    def parse_command_options(command, args)
      parser = COMMAND_OPTION_PARSERS[command]
      if parser
        parser.call(args)
      else
        {}
      end
    end

    def self.create_option_parser(schema_opts)
      lambda do |args|
        parsed_options = {}
        begin
          OptionParser.new do |opt|
            schema_opts.each { |schema_opt| schema_opt.call(opt, parsed_options) }
          end.order!(args)
        rescue OptionParser::ParseError => e
          raise ArgumentError, e.message
        end
        parsed_options
      end
    end

    def create_global_option_parser(exec_name)
      self.class.create_option_parser [
        lambda { |opt, parsed|
          opt.banner =<<-EOS
A simple but tasty Twitter agent for command line use, made for fun.

Usage: #{exec_name} [global_options...] [command] [command_options...]

  [command] is one of {#{Client::COMMANDS.join(", ")}},
  defaulting to #{Client::DEFAULT_COMMAND}.

  [global_options]:

          EOS
        },

        lambda { |opt, parsed|
          opt.on("-a", "--auth USERNAME:PASSWORD", "Authentication") { |arg|
            parsed[:username], parsed[:password] = arg.split(":", 2)
          }
        },

        lambda { |opt, parsed|
          opt.on("-c", "--colorize", "Colorize output with ANSI escape codes") {
            parsed[:colorize] = true
          }
        },

        lambda { |opt, parsed|
          opt.on("-n", "--num N", Integer, "The number of statuses to fetch, defaults to #{Client::DEFAULT_NUM_STATUSES}") { |arg|
            parsed[:num_statuses] = arg
          }
        },

        lambda { |opt, parsed|
          opt.on("--no-colorize", "Do not colorize output with ANSI escape codes") {
            parsed[:colorize] = false
          }
        },

        lambda { |opt, parsed|
          opt.on("--no-url-shorten", "Do not shorten URLs for status update") {
            parsed[:shorten_urls] = { :enable => false }
          }
        },

        lambda { |opt, parsed|
          opt.on("-p", "--page N", Integer, "The page number of the statuses to fetch, defaults to #{Client::DEFAULT_PAGE_NUM}") { |arg|
            parsed[:page_num] = arg
          }
        },

        lambda { |opt, parsed|
          opt.on("-v", "--version", "Show version information and exit") {
            puts "#{exec_name} #{Tweetwine::VERSION}"
            exit(EXIT_VERSION)
          }
        },

        lambda { |opt, parsed|
          opt.on_tail("-h", "--help", "Show this help message and exit") {
            puts opt
            exit(EXIT_HELP)
          }
        }
      ]
    end

    def self.create_search_option_parser
      create_option_parser [
        lambda { |opt, parsed|
          opt.on("-a", "--and", "All words must match") { parsed[:and] = true }
        },

        lambda { |opt, parsed|
          opt.on("-o", "--or", "Any word can match") { parsed[:or] = true }
        }
      ]
    end

    COMMAND_OPTION_PARSERS = {
      :search => lambda { |args| create_search_option_parser.call(args) }
    }
  end
end
