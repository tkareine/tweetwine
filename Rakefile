# coding: utf-8

require 'rake/clean'

$LOAD_PATH.unshift(File.expand_path('lib', File.dirname(__FILE__)))
name = 'tweetwine'
require "#{name}/version"
version = Tweetwine.version

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

CLOBBER.include 'rdoc'
desc "Generate RDoc"
task :rdoc do
  sh %{rdoc --encoding=UTF-8 --line-numbers --title='#{name} #{version}' --output=rdoc *.rdoc LICENSE.txt lib}
end

namespace :test do
  def create_test_task(type, options = {})
    base_dir  = options[:base_dir]
    file_glob = options[:file_glob]
    test_desc = options[:desc] || "Run #{type} tests"
    includes  = ['lib', 'test', base_dir].map { |dir| "-I #{dir}" }.join(' ')
    warn_opt  = options[:warn] ? '-w' : ''

    desc test_desc
    task type do
      file_name_offset = base_dir.size + 1
      neg_dotrb_suffix = -'.rb'.size - 1
      tests = FileList["#{base_dir}/#{file_glob}"].
          map { |file| '"' << file[file_name_offset..neg_dotrb_suffix] << '"' }.
          join(' ')
      sh %{bundle exec ruby #{warn_opt} #{includes} -e 'ARGV.each { |f| require f }' #{tests}}
    end
  end

  create_test_task :unit,
      :base_dir   => 'test/unit',
      :file_glob  => '**/*_test.rb',
      :warn       => true
  create_test_task :example,
      :base_dir   => 'test/example',
      :file_glob  => '**/*_example.rb',
      :desc       => 'Run integration/example tests',
      :warn       => false

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
