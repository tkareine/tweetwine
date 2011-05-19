# coding: utf-8

require 'support/integration_test_case'
require 'fileutils'

module Tweetwine::Test::Integration

class InvalidConfigFileTest < TestCase
  before do
    in_tmp_dir do
      config_file = 'tweetwine.tmp'
      FileUtils.touch config_file
      @status = start_app %W{--no-colors -f #{config_file}} do |_, _, _, stderr|
        @output = stderr.readlines.join.chomp
      end
    end
  end

  it "shows just the error message (not the whole stack trace)" do
    @output.must_match(/\AERROR: invalid config file; it must be a mapping style YAML document: /)
  end

  it "exists with failure status" do
    @status.exitstatus.must_equal ConfigError.status_code
  end
end

end
