# coding: utf-8

$LOAD_PATH.unshift(File.expand_path('lib', File.dirname(__FILE__)))
name = 'tweetwine'
require "#{name}/version"
version = Tweetwine.version

Gem::Specification.new do |s|
  s.name = name
  s.version = version.dup

  s.summary = Tweetwine.summary
  s.description = <<-END
A simple but tasty Twitter agent for command line use, designed for quickly
showing the latest tweets.
  END

  s.email = 'tkareine@gmail.com'
  s.homepage = 'https://github.com/tkareine/tweetwine'

  s.authors = ['Tuomas Kareinen']

  s.files = `git ls-files`.split("\n") + Dir['man/**/*.[1-9]']
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  s.add_dependency 'oauth', '~> 0.4.4'
  s.add_development_dependency 'contest',       '~> 0.1.2'
  s.add_development_dependency 'coulda',        '~> 0.6.3'
  s.add_development_dependency 'gem-man',       '~> 0.2.0'
  s.add_development_dependency 'mcmire-matchy', '~> 0.5.2'
  s.add_development_dependency 'mocha',         '~> 0.9.12'
  s.add_development_dependency 'open4',         '~> 1.0.1'
  s.add_development_dependency 'ronn',          '~> 0.7.3'
  s.add_development_dependency 'timecop',       '~> 0.3.5'
  s.add_development_dependency 'webmock',       '~> 1.6.2'

  s.post_install_message = <<-END

Tweetwine requires a JSON parser library. Ruby 1.9 comes bundled with one by
default. For Ruby 1.8, you can install 'json' gem, for example.

  END

  s.has_rdoc = true
  s.extra_rdoc_files = Dir['*.rdoc', 'LICENSE.txt']
  s.rdoc_options << '--title'   << "#{name} #{version}" \
                 << '--exclude' << 'test'
end
