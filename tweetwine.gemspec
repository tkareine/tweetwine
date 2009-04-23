# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tweetwine}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tuomas Kareinen"]
  s.date = %q{2009-04-23}
  s.default_executable = %q{tweetwine}
  s.description = %q{A simple but tasty Twitter agent for command line use, made for fun.}
  s.email = %q{tkareine@gmail.com}
  s.executables = ["tweetwine"]
  s.extra_rdoc_files = ["CHANGELOG.rdoc", "README.rdoc"]
  s.files = ["Rakefile", "CHANGELOG.rdoc", "README.rdoc", "bin/tweetwine", "lib/tweetwine", "lib/tweetwine/client.rb", "lib/tweetwine/config.rb", "lib/tweetwine/io.rb", "lib/tweetwine/util.rb", "lib/tweetwine.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/tuomas/tweetwine}
  s.rdoc_options = ["--title", "Tweetwine 0.1.1", "--main", "README.rdoc", "--exclude", "spec", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{A simple Twitter agent for command line use}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 1.1.4"])
      s.add_runtime_dependency(%q<rest-client>, [">= 0.9.2"])
    else
      s.add_dependency(%q<json>, [">= 1.1.4"])
      s.add_dependency(%q<rest-client>, [">= 0.9.2"])
    end
  else
    s.add_dependency(%q<json>, [">= 1.1.4"])
    s.add_dependency(%q<rest-client>, [">= 0.9.2"])
  end
end
