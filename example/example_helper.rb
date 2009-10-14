require "coulda"
require "matchy"
require "open4"
require "tweetwine"

module Tweetwine
  module ExampleHelpers
    EXIT_INJECTION_LOAD_ERROR = 41
    EXIT_INJECTION_OTHER_ERROR = 42

    DEFAULT_INJECTION =<<-END
require "fakeweb"
FakeWeb.allow_net_connect = false

require "date"    # a workaround for Timecop bug
require "time"
require "timecop"
Timecop.freeze(Time.parse("2009-10-14 01:56:15 +0300"))

def fixture(filename)
  contents = nil
  filepath = File.dirname(__FILE__) << "/example/fixtures/" << filename
  File.open(filepath) do |f|
    contents = f.readlines.join("\n")
  end
  contents
end
    END

    def launch_app(args, injection_code = "", &blk)
      lib = File.dirname(__FILE__) << "/../lib"
      executable = File.dirname(__FILE__) << "/../bin/tweetwine"
      code = inject_code_to_executable(executable, injection_code)
      launch_cmd = "ruby -rubygems -I#{lib} -e \"#{code}\" -- #{args}"
      process_status = Open4::popen4(launch_cmd, &blk)
      exit_if_injection_execution_error(process_status)
      process_status
    end

    private

    def exit_if_injection_execution_error(process_status)
      if process_status.exited?
        exit_status = process_status.exitstatus
        case exit_status
        when EXIT_INJECTION_LOAD_ERROR
          $stderr.puts "Load error in executing injected code -- perhaps a gem is missing?"
          exit(exit_status)
        when EXIT_INJECTION_OTHER_ERROR
          $stderr.puts "Unknown error in executing injected code"
          exit(exit_status)
        end
      end
    end

    def inject_code_to_executable(executable, code)
      "#{make_injection_code(code)}; `cat #{executable}`"
    end

    def make_injection_code(code)
      injection =<<-END
begin
  #{DEFAULT_INJECTION}
  #{code}
rescue LoadError => e
  $stderr.puts e
  exit #{EXIT_INJECTION_LOAD_ERROR}
rescue Exception => e
  $stderr.puts e.backtrace.join("\n")
  exit #{EXIT_INJECTION_OTHER_ERROR}
end
      END
      escape_injection_for_shell(injection)
    end

    def escape_injection_for_shell(code)
      [['\'', '\\\''], ['"', '\\"'], ['$', '\\$']].inject(code.dup) do |result, pair|
        result.gsub!(pair.first, pair.last)
        result
      end
    end
  end
end

module Test
  module Unit
    class TestCase
      include Tweetwine::ExampleHelpers
    end
  end
end

include Coulda
include Tweetwine
