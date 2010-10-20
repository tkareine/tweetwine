# coding: utf-8

require "rake/clean"

$LOAD_PATH.unshift(File.expand_path("../lib/", __FILE__))
name = "tweetwine"
require name
version = Tweetwine::VERSION.dup

namespace :gem do
  CLOBBER.include "#{name}-*.gem"

  file "#{name}-#{version}.gem" do |f|
    sh %{gem build #{name}.gemspec}
  end

  desc "Package the software as a gem"
  task :build => [:"man:build", :"test:all", "#{name}-#{version}.gem"]

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

  desc "Show the manual section 7"
  task :show => :build do
    sh "man man/#{name}.7"
  end
end

namespace :test do
  def create_test_task(type, file_glob, options = {})
    test_dir  = file_glob[%r{(\w+)/}, 1]
    test_desc = options[:desc] || "Run #{type} tests"
    includes  = (options[:includes] || ['lib', test_dir]).map { |dir| "-I #{dir}" }.join(' ')
    warn_opt  = options[:warn] ? "-w" : ""

    desc test_desc
    task type do
      tests = FileList[file_glob].map { |f| "\"#{f[test_dir.size+1 .. -4]}\"" }.join(' ')
      sh %{ruby -rubygems #{warn_opt} #{includes} -e 'ARGV.each { |f| require f }' #{tests}}
    end
  end

  create_test_task :unit,     'test/**/*_test.rb',        :warn => true
  create_test_task :example,  'example/**/*_example.rb',  :warn => false, :includes => %w{lib test example}, :desc => "Run integration/example tests"

  desc "Run all tests"
  task :all => [:unit, :example]
end

desc "Find code smells"
task :roodi do
  sh %{roodi "**/*.rb"}
end

desc "Show parts of the project tagged as incomplete"
task :todo do
  FileList["**/*.*"].egrep /(TODO|FIXME)/
end

task :default => :"test:all"
