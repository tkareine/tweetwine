require "rubygems"

package_name = "tweetwine"
require "lib/#{package_name}"
full_name = Tweetwine::Meta::NAME
version = Tweetwine::Meta::VERSION

require "rake/clean"

require "rake/gempackagetask"
spec = Gem::Specification.new do |s|
  s.name = package_name
  s.version = version
  s.homepage = "http://github.com/tuomas/tweetwine"
  s.summary = "A simple Twitter agent for command line use"
  s.description = "A simple but tasty Twitter agent for command line use, made for fun."

  s.author = "Tuomas Kareinen"
  s.email = "tkareine@gmail.com"

  s.platform = Gem::Platform::RUBY
  s.files = FileList["Rakefile", "MIT-LICENSE.txt", "*.rdoc", "bin/**/*", "lib/**/*", "test/**/*"].to_a
  s.executables = ["tweetwine"]

  s.add_dependency("rest-client", ">= 1.0.0")

  s.has_rdoc = true
  s.extra_rdoc_files = FileList["MIT-LICENSE.txt", "*.rdoc"].to_a
  s.rdoc_options << "--title"   << "#{full_name} #{version}" \
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

task :install => [:package] do
  sh %{sudo gem install pkg/#{package_name}-#{version}.gem}
end

task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{package_name}}
end

require "rake/rdoctask"
desc "Create documentation"
Rake::RDocTask.new(:rdoc) do |rd|
  rd.rdoc_dir = "rdoc"
  rd.title = "#{full_name} #{version}"
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
  t.libs << "test"
end

desc "Find code smells"
task :roodi do
  sh %{roodi "**/*.rb"}
end

desc "Search unfinished parts of source code"
task :todo do
  FileList["**/*.rb"].egrep /#.*(TODO|FIXME)/
end

task :default => :test
