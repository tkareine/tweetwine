# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tweetwine}
  s.version = "0.1.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tuomas Kareinen"]
  s.date = %q{2009-07-15}
  s.default_executable = %q{tweetwine}
  s.description = %q{A simple but tasty Twitter agent for command line use, made for fun.}
  s.email = %q{tkareine@gmail.com}
  s.executables = ["tweetwine"]
  s.extra_rdoc_files = ["CHANGELOG.rdoc", "README.rdoc"]
  s.files = ["Rakefile", "CHANGELOG.rdoc", "README.rdoc", "bin/tweetwine", "lib/tweetwine", "lib/tweetwine/client.rb", "lib/tweetwine/io.rb", "lib/tweetwine/startup_config.rb", "lib/tweetwine/util.rb", "lib/tweetwine.rb", "test/client_test.rb", "test/io_test.rb", "test/startup_config_test.rb", "test/test_config.yaml", "test/test_helper.rb", "test/util_test.rb"]
  s.homepage = %q{http://github.com/tuomas/tweetwine}
  s.rdoc_options = ["--title", "Tweetwine 0.1.9", "--main", "README.rdoc", "--exclude", "test", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{A simple Twitter agent for command line use}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 1.0.0"])
    else
      s.add_dependency(%q<rest-client>, [">= 1.0.0"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 1.0.0"])
  end
end
