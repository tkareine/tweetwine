# coding: utf-8

module Tweetwine
  module CLI
    DEFAULT_COMMAND = :home
    DEFAULT_CONFIG = {
      :colors       => :false,
      :config_file  => "#{(ENV['HOME'] || ENV['USERPROFILE'])}/.tweetwine",
      :env_lookouts => [:http_proxy],
      :excludes     => [:command],
      :shorten_urls => {:disable => true},
      :username     => ENV['USER']
    }.freeze
    EXEC_NAME = 'tweetwine'

    class << self
      def start(args = ARGV, overriding_default_conf = nil)
        init(args, overriding_default_conf)
        run(args)
      end

      def config
        @config ||= read_config
      end

      def http
        @http ||= Http::Client.new(config)
      end

      def oauth
        @oauth ||= OAuth.new(config[:oauth_access])
      end

      def twitter
        @twitter ||= Twitter.new(config)
      end

      def ui
        @ui ||= UI.new(config)
      end

      def url_shortener
        @url_shorterer ||= UrlShortener.new(config[:shorten_urls])
      end

      def commands
        @commands ||= {
          :primaries    => {},
          :secondaries  => {}
        }
      end

      def register_command(cmd_class, names)
        commands[:primaries][names.first.to_sym] = cmd_class
        names[1..-1].each { |name| commands[:secondaries][name.to_sym] = cmd_class }
      end

      def find_command(name)
        name = name.to_sym
        commands[:primaries][name] || commands[:secondaries][name]
      end

      def global_option_parser
        @global_option_parser ||= OptionParser.new do |parser, options|
          parser.on '-c', '--colors',                     'Enable ANSI colors for output.' do
            options[:colors] = true
          end
          parser.on '-f', '--config <file>',    String,   "Configuration file (default #{DEFAULT_CONFIG[:config_file]})." do |arg|
            options[:config_file] = arg
          end
          parser.on '-h', '--help',                       'Show this help and exit.' do
            options[:command] = :help
          end
          parser.on       '--http-proxy <url>', String,   'Enable HTTP(S) proxy.' do |arg|
            options[:http_proxy] = arg
          end
          parser.on       '--no-colors',                  'Disable ANSI colors for output.' do
            options[:colors] = false
          end
          parser.on       '--no-http-proxy',              'Disable HTTP(S) proxy.' do
            options[:http_proxy] = nil
          end
          parser.on       '--no-url-shorten',             'Disable URL shortening.' do
            options[:shorten_urls] ||= {}
            options[:shorten_urls][:disable] = true
          end
          parser.on '-n', '--num <n>',          Integer,  "Number of statuses per page (default #{Twitter::DEFAULT_NUM_STATUSES})." do |arg|
            options[:num_statuses] = arg
          end
          parser.on '-p', '--page <p>',         Integer,  "Page number for statuses (default #{Twitter::DEFAULT_PAGE_NUM})." do |arg|
            options[:page] = arg
          end
          parser.on '-u', '--username <user>',  String,   "User to authenticate (default '#{DEFAULT_CONFIG[:username]}')." do |arg|
            options[:username] = arg
          end
          parser.on '-v', '--version',                    "Show version and exit." do
            options[:command] = :version
          end
        end
      end

      private

      def init(args, overriding_default_conf = nil)
        @config, @http, @oauth, @twitter, @ui, @url_shortener = nil   # reset
        @config = read_config(args, overriding_default_conf)
      end

      def run(args)
        proposed_command = config[:command]
        found_command = find_command proposed_command
        raise UnknownCommandError, "unknown command: #{proposed_command}" unless found_command
        found_command.new(args).run
        self
      end

      def read_config(cmdline_args = [], overriding_default_config = nil)
        default_config = overriding_default_config ? DEFAULT_CONFIG.merge(overriding_default_config) : DEFAULT_CONFIG
        config = Config.read(cmdline_args, default_config) do |args|
          parse_config_from_cmdline(args)
        end
        config
      end

      def parse_config_from_cmdline(args)
        options = global_option_parser.parse(args)
        unless options[:command]
          cmd_via_arg = args.shift
          options[:command] = cmd_via_arg ? cmd_via_arg.to_sym : DEFAULT_COMMAND
        end
        options
      end
    end
  end

  class Command
    class << self
      def inherited(child)
        # Silence warnings about uninitialized variables if a child does not
        # set its about, name, or usage.
        child.instance_eval do
          @about, @name, @usage = nil
        end
      end

      def about(description = nil)
        return @about unless description
        @about = description.chomp
      end

      def register(*names)
        @name = names.first
        CLI.register_command(self, names)
      end

      def name
        @name
      end

      # Usage description for the command, use if overriding #parse.
      def usage(description = nil)
        return @usage unless description
        @usage = description
      end

      def show_usage(about_cmd = self)
        about = about_cmd.about
        name = about_cmd.name
        usage = about_cmd.usage
        result = <<-END
#{about}

Usage: #{CLI::EXEC_NAME} #{name} #{usage}
        END
        CLI.ui.info result.strip!
      end

      def abort_with_usage
        show_usage
        exit CommandLineError.status_code
      end
    end

    def initialize(args)
      parsing_succeeded = parse(args)
      self.class.abort_with_usage unless parsing_succeeded
    end

    # Default behavior, which succeeds always; override for real argument
    # parsing if the command needs arguments.
    def parse(args)
      true
    end
  end

  class HelpCommand < Command
    register "help"
    about "Show help and exit. Try it with <command> argument."
    usage <<-END
[<command>]

  If <command> is given, show specific help about that command. If no
  <command> is given, show general help.
    END

    def parse(args)
      # Did we arrive here via '-h' option? If so, we cannot have
      # +proposed_command+ because '-h' does not take an argument. Otherwise,
      # try to read the argument.
      proposed_command = args.include?('-h') ? nil : args.shift
      if proposed_command
        @command = CLI.find_command proposed_command
        CLI.ui.error "unknown command: #{proposed_command}\n\n" unless @command
        @command
      else
        @command = nil
        true
      end
    end

    def run
      if @command
        show_command_help
      else
        show_general_help
      end
    end

    private

    def show_command_help
      self.class.show_usage @command
    end

    def show_general_help
      command_descriptions = CLI.commands[:primaries].
        entries.
        sort     { |a, b| a.first.to_s <=> b.first.to_s }.
        map      { |cmd, klass| [cmd, klass.about] }
      CLI.ui.info <<-END
#{Tweetwine.summary}

Usage: #{CLI::EXEC_NAME} [global_options...] [<command>] [command_options...]

  Global options:

#{CLI.global_option_parser.help}

  Commands:

#{command_descriptions.map { |cmd, desc| "    %-14s%s" % [cmd, desc] }.join("\n") }
      END
    end
  end

  class HomeCommand < Command
    register "home", "h"
    about "Show authenticated user's home timeline (the default command)."

    def run
      CLI.twitter.home
    end
  end

  class FollowersCommand < Command
    register "followers", "fo"
    about "Show authenticated user's followers and their latest tweets."

    def run
      CLI.twitter.followers
    end
  end

  class FriendsCommand < Command
    register "friends", "fr"
    about "Show authenticated user's friends and their latest tweets."

    def run
      CLI.twitter.friends
    end
  end

  class MentionsCommand < Command
    register "mentions", "men", "m"
    about "Show latest tweets that mention or are replies to the authenticated user."

    def run
      CLI.twitter.mentions
    end
  end

  class SearchCommand < Command
    def self.parser
      @parser ||= OptionParser.new do |parser, options|
        parser.on '-a', '--and',  'All words match (default).' do
          options[:operator] = :and
        end
        parser.on '-o', '--or',   'Any word matches.' do
          options[:operator] = :or
        end
      end
    end

    register "search", "s"
    about "Search latest public tweets."
    usage(Promise.new {<<-END
[--all | --or] <word>...

  Command options:

#{parser.help}
      END
    })

    def parse(args)
      options = self.class.parser.parse(args)
      @operator = options[:operator]
      @words = args
      if @words.empty?
        CLI.ui.error "No search words.\n\n"
        false
      else
        true
      end
    end

    def run
      CLI.twitter.search @words, @operator
    end
  end

  class UpdateCommand < Command
    register "update", "up"
    about "Send new tweet."
    usage <<-END
[<status>]

  If <status> is not given, read the contents for the tweet from STDIN.
    END

    def parse(args)
      @msg = args.join(' ')
      args.clear
      true
    end

    def run
      CLI.twitter.update @msg
    end
  end

  class UserCommand < Command
    register "user", "usr"
    about "Show user's timeline."
    usage <<-END
[<username>]

  If <username> is not given, show authenticated user's timeline.
    END

    def parse(args)
      @user = args.empty? ? CLI.config[:username] : args.shift
    end

    def run
      CLI.twitter.user(@user)
    end
  end

  class VersionCommand < Command
    register "version", "ver", "v"
    about "Show program version and exit."

    def run
      CLI.ui.info "tweetwine #{Tweetwine.version}"
    end
  end
end
