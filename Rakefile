# coding: utf-8

require "rake/clean"

$LOAD_PATH.unshift(File.expand_path("../lib/", __FILE__))
name = "tweetwine"
require "#{name}/meta"
version = Tweetwine::VERSION.dup

namespace :gem do
  CLOBBER.include "#{name}-*.gem"

  file "#{name}.gem" => :"man:build" do |f|
    sh %{gem build #{name}.gemspec}
  end

  desc "Package the software as a gem"
  task :build => "#{name}.gem"

  desc "Install the software as a gem"
  task :install => :build do
    sh %{gem install #{name}-#{version}.gem}
  end

  desc "Uninstall the gem"
  task :uninstall => :clean do
    sh %{gem uninstall #{name}}
  end
end

namespace :man do
  CLOBBER.include "man/#{name}.?", "man/#{name}.?.html"

  desc "Build the manual"
  task :build do
    sh "ronn -br5 --manual='#{name.capitalize} Manual' --organization='Tuomas Kareinen' man/*.ronn"
  end

  desc "Show the manual"
  task :show => :build do
    sh "man man/#{name}.1"
  end
end

namespace :test do
  require "rake/testtask"

  desc "Run unit tests"
  Rake::TestTask.new(:unit) do |t|
    t.test_files = FileList["test/**/*_test.rb"]
    t.verbose = true
    t.warning = true
    t.ruby_opts << "-rrubygems"
    t.libs << "test"
  end

  desc "Run integration/example tests"
  Rake::TestTask.new(:example) do |t|
    t.test_files = FileList["example/**/*_example.rb"]
    t.verbose = true
    t.warning = false
    t.ruby_opts << "-rrubygems"
    t.libs << "example"
  end
end

desc "Find code smells"
task :roodi do
  sh %{roodi "**/*.rb"}
end

desc "Show parts of the project tagged as incomplete"
task :todo do
  FileList["**/*.*"].egrep /(TODO|FIXME)/
end

task :default => [:"test:unit", :"test:example"]
