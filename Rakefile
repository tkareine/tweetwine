# coding: utf-8

require File.expand_path('project', File.dirname(__FILE__))

require 'rake/clean'
require 'shellwords'

desc "Benchmark (profile) fetching home timeline"
task :bm do
  sh %{ruby -rubygems -I lib -I test benchmark/home_bm.rb}
end

namespace :gem do
  CLOBBER.include "#{Project[:spec][:name]}-*.gem"

  desc "Package the software as a gem"
  task :build => [:"man:build", :"test:all"] do
    sh %{gem build #{Project[:spec][:name]}.gemspec}
  end

  desc "Install the software as a gem"
  task :install => :build do
    sh %{gem install #{current_gem}}
  end

  desc "Uninstall the gem"
  task :uninstall => :clean do
    sh %{gem uninstall #{Project[:spec][:name]}}
  end
end

namespace :man do
  CLOBBER.include "#{Project[:dir][:man]}/#{Project[:spec][:name]}.?", "#{Project[:dir][:man]}/#{Project[:spec][:name]}.?.html"

  desc "Build the manual"
  task :build do
    sh %{ronn --html --roff --manual='#{Project[:spec][:name].capitalize} Manual' --organization='#{Project[:spec][:authors].first}' #{Project[:dir][:man]}/*.ronn}
  end

  desc "Show the manual section 7"
  task :show => :build do
    sh %{man #{Project[:dir][:man]}/#{Project[:spec][:name]}.7}
  end
end

CLOBBER.include Project[:dir][:rdoc]

desc "Generate RDoc"
task :rdoc do
  sh %{rdoc --encoding=UTF-8 --line-numbers --title='#{Project[:extra][:title]}' --output=#{Project[:dir][:rdoc]} *.rdoc LICENSE.txt lib}
end

namespace :test do
  def create_test_task(type, options = {})
    base_dir  = options[:base_dir]
    file_glob = options[:file_glob] || '**/*_test.rb'
    test_desc = options[:desc] || "Run #{type} tests"
    includes  = ['lib', Project[:dir][:test]].map { |dir| "-I #{dir}" }.join(' ')
    warn_opt  = options[:warn] ? '-w' : ''

    desc test_desc
    task type do
      file_name_offset = Project[:dir][:test].size + 1
      neg_dotrb_suffix = -'.rb'.size - 1
      tests = Dir["#{base_dir}/#{file_glob}"].
          map { |file| file[file_name_offset..neg_dotrb_suffix] }.
          shelljoin
      sh %{bundle exec ruby #{warn_opt} #{includes} -e 'ARGV.each { |f| require f }' #{tests}}
    end
  end

  create_test_task :unit,
      :base_dir   => "#{Project[:dir][:test]}/unit",
      :warn       => true

  create_test_task :integration,
      :base_dir   => "#{Project[:dir][:test]}/integration",
      :warn       => false

  desc "Run all tests"
  task :all => [:unit, :integration]
end

desc "Find code smells"
task :roodi do
  sh %{roodi "**/*.rb"}
end

desc "Show parts of the project tagged as incomplete"
task :todo do
  FileList["**/*.*"].egrep(/(TODO|FIXME)/)
end

task :default => :"test:all"
