# coding: utf-8

require File.expand_path('project', File.dirname(__FILE__))

Gem::Specification.new do |s|
  Project[:spec].each { |(key, value)| s.send "#{key}=", value }

  s.files = `git ls-files`.split("\n") + Dir["#{Project[:dir][:man]}/**/*.[1-9]"]
  s.test_files = `git ls-files -- #{Project[:dir][:test]}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  s.add_dependency 'oauth', '~> 0.4.4'
  s.add_development_dependency 'gem-man',       '~> 0.3.0'
  s.add_development_dependency 'minitest',      '~> 2.12.1'
  s.add_development_dependency 'mocha',         '~> 0.11.3'
  s.add_development_dependency 'open4',         '~> 1.3.0'
  s.add_development_dependency 'rake',          '>= 0.8.7'
  s.add_development_dependency 'ronn',          '~> 0.7.3'
  s.add_development_dependency 'timecop',       '~> 0.3.5'
  s.add_development_dependency 'webmock',       '~> 1.8.6'

  s.post_install_message = <<-END

Tweetwine requires a JSON parser library. Ruby 1.9 comes bundled with one by
default. For Ruby 1.8, you can install 'json' gem, for example.

  END

  s.extra_rdoc_files = Dir['*.rdoc', 'LICENSE.txt']
  s.rdoc_options << '--title' << Project[:extra][:title] << '--exclude' << Project[:dir][:test]
end
