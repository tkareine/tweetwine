require "coulda"
require "matchy"
require "open4"
require "tweetwine"

module Tweetwine
  module ExampleHelpers
    DEFAULT_INJECTION =<<-END
require "fakeweb"
FakeWeb.allow_net_connect = false

require "date"
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
      code =<<-END
#{escape_injection_for_shell(DEFAULT_INJECTION)}
#{escape_injection_for_shell(injection_code)}
`cat #{executable}`
      END
      launch_cmd = "ruby -rubygems -I#{lib} -e \"#{code}\" -- #{args}"
      Open4::popen4(launch_cmd, &blk)
    end

    private

    def escape_injection_for_shell(code)
      code_dup = code.dup
      code_dup.gsub!('\'', '\\\'')
      code_dup.gsub!('"', '\\"')
      code_dup
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
