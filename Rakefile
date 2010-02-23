$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "rubygems"

name = "tweetwine"
require "#{name}"
version = Tweetwine::VERSION.dup

require "rake/clean"

require "rake/gempackagetask"
spec = Gem::Specification.new do |s|
  s.name = name
  s.version = version
  s.homepage = "http://github.com/tuomas/tweetwine"
  s.summary = "A simple Twitter agent for command line use"
  s.description = "A simple but tasty Twitter agent for command line use, made for fun."

  s.author = "Tuomas Kareinen"
  s.email = "tkareine@gmail.com"

  s.platform = Gem::Platform::RUBY
  s.files = FileList[
    "Rakefile",
    "MIT-LICENSE.txt",
    "*.rdoc",
    "bin/**/*",
    "contrib/**/*",
    "example/**/*",
    "lib/**/*",
    "test/**/*"].to_a
  s.executables = ["tweetwine"]

  s.add_dependency("rest-client", ">= 1.0.0")

  s.has_rdoc = true
  s.extra_rdoc_files = FileList["MIT-LICENSE.txt", "*.rdoc"].to_a
  s.rdoc_options << "--title"   << "#{name} #{version}" \
                 << "--main"    << "README.rdoc" \
                 << "--exclude" << "test" \
                 << "--line-numbers"
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = true
end

desc "Generate a gemspec file"
task :gemspec do
  File.open("#{spec.name}.gemspec", "w") do |f|
    f.write spec.to_ruby
  end
end

desc "Install the software as a gem"
task :install => [:package] do
  sh %{gem install pkg/#{name}-#{version}.gem}
end

desc "Uninstall the gem"
task :uninstall => [:clean] do
  sh %{gem uninstall #{name}}
end

require "rake/rdoctask"
desc "Create documentation"
Rake::RDocTask.new(:rdoc) do |rd|
  rd.rdoc_dir = "rdoc"
  rd.title = "#{name} #{version}"
  rd.main = "README.rdoc"
  rd.rdoc_files.include("MIT-LICENSE.txt", "*.rdoc", "lib/**/*.rb")
  rd.options << "--line-numbers"
end

require "rake/testtask"
desc "Run tests"
Rake::TestTask.new(:test) do |t|
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
  t.warning = true
  t.ruby_opts << "-rrubygems"
  t.libs << "test"
end

Rake::TestTask.new(:example) do |t|
  t.test_files = FileList["example/**/*_example.rb"]
  t.verbose = true
  t.warning = false
  t.ruby_opts << "-rrubygems"
  t.libs << "example"
end

desc "Find code smells"
task :roodi do
  sh %{roodi "**/*.rb"}
end

desc "Search unfinished parts of source code"
task :todo do
  FileList["**/*.rb", "**/*.rdoc", "**/*.txt"].egrep /(TODO|FIXME)/
end

task :default => [:test, :example]
