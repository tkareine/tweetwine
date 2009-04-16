require "rubygems"

FULL_NAME = "Tweetwine"
PACKAGE_NAME = "tweetwine"
VERSION = "0.0.0"

require "lib/#{PACKAGE_NAME}"

require "rake/clean"

require "rake/gempackagetask"
spec = Gem::Specification.new do |s|
  s.name = PACKAGE_NAME
  s.version = VERSION
  s.homepage = "http://github.com/tuomas/tweetwine"
  s.summary = "A Twitter reader"
  s.description =<<-END
A tasty Twitter reader made for fun.
  END

  s.author = "Tuomas Kareinen"
  s.email = "tkareine@gmail.com"

  s.files = FileList["lib/**/*.rb", "bin/**/*", "*.rdoc", "spec/**/*.rb"].to_a
  s.executables << "tweetwine"

  s.add_development_dependency("rspec", ">= 1.2.0")

  s.has_rdoc = true
  s.extra_rdoc_files = FileList["*.rdoc"].to_a
  s.rdoc_options << "--title"   << "#{FULL_NAME} #{VERSION}" \
                 << "--main"    << "README.rdoc" \
                 << "--exclude" << "spec" \
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

require "rake/rdoctask"
desc "Create documentation"
Rake::RDocTask.new(:rdoc) do |rd|
  rd.title = "#{FULL_NAME} #{VERSION}"
  rd.main = "README.rdoc"
  rd.rdoc_files.include("*.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
  rd.options << "--line-numbers"
end

require "spec/rake/spectask"
desc "Run specs"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList["spec/**/*.rb"]
  t.spec_opts = ["--format", "specdoc"]
  t.rcov = true
  t.rcov_opts = ["--exclude", "spec"]
  #t.warning = true
end

desc "Find code smells"
task :roodi do
  sh("roodi '**/*.rb'")
end

desc "Search unfinished parts of source code"
task :todo do
  FileList["**/*.rb"].egrep /#.*(TODO|FIXME)/
end

#task :default => :spec
