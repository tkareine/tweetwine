# coding: utf-8

$LOAD_PATH.unshift(File.expand_path("../lib/", __FILE__))
name = "tweetwine"
require name
version = Tweetwine::VERSION.dup

Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = name
  s.version = version
  s.homepage = "http://github.com/tuomas/tweetwine"

  s.summary = "A simple Twitter command line agent"
  s.description = "A simple but tasty Twitter agent for command line use, made for fun."

  s.authors = "Tuomas Kareinen"
  s.email = "tkareine@gmail.com"

  s.files = Dir[
    "*.md",
    "*.rdoc",
    "LICENSE.txt",
    "Gemfile",
    "Rakefile",
    "tweetwine.gemspec",
    "{bin,contrib,example,lib,test}/**/*",
    "man/**/*.[1-9]",
    "man/**/*.ronn"
  ]
  s.require_paths = %w{lib}
  s.executables = %w{tweetwine}

  s.add_dependency "oauth", "~> 0.4.4"
  s.add_dependency "json",  ">= 1.0.0"
  s.add_development_dependency "contest", "~> 0.1.2"
  s.add_development_dependency "coulda",  "~> 0.6.0"
  s.add_development_dependency "gem-man", "~> 0.2.0"
  s.add_development_dependency "matchy",  "~> 0.5.2"
  s.add_development_dependency "mocha",   "=  0.9.8"
  s.add_development_dependency "open4",   "~> 1.0.1"
  s.add_development_dependency "ronn",    "~> 0.7.3"
  s.add_development_dependency "timecop", "~> 0.3.5"
  s.add_development_dependency "webmock", "~> 1.6.1"

  s.has_rdoc = true
  s.extra_rdoc_files = Dir["*.rdoc", "LICENSE.txt"]
  s.rdoc_options << "--title"   << "#{name} #{version}" \
                 << "--exclude" << "test"
end
