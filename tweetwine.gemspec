# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tweetwine}
  s.version = "0.2.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tuomas Kareinen"]
  s.date = %q{2009-12-22}
  s.default_executable = %q{tweetwine}
  s.description = %q{A simple but tasty Twitter agent for command line use, made for fun.}
  s.email = %q{tkareine@gmail.com}
  s.executables = ["tweetwine"]
  s.extra_rdoc_files = ["MIT-LICENSE.txt", "CHANGELOG.rdoc", "README.rdoc"]
  s.files = ["Rakefile", "MIT-LICENSE.txt", "CHANGELOG.rdoc", "README.rdoc", "bin/tweetwine", "example/example_helper.rb", "example/fixtures", "example/fixtures/home.json", "example/fixtures/mentions.json", "example/fixtures/search.json", "example/fixtures/update.json", "example/fixtures/user.json", "example/fixtures/users.json", "example/search_statuses_example.rb", "example/show_followers_example.rb", "example/show_friends_example.rb", "example/show_home_example.rb", "example/show_mentions_example.rb", "example/show_metadata_example.rb", "example/show_user_example.rb", "example/update_status_example.rb", "lib/tweetwine", "lib/tweetwine/cli.rb", "lib/tweetwine/client.rb", "lib/tweetwine/io.rb", "lib/tweetwine/meta.rb", "lib/tweetwine/options.rb", "lib/tweetwine/retrying_http.rb", "lib/tweetwine/startup_config.rb", "lib/tweetwine/url_shortener.rb", "lib/tweetwine/util.rb", "lib/tweetwine.rb", "test/cli_test.rb", "test/client_test.rb", "test/fixtures", "test/fixtures/test_config.yaml", "test/io_test.rb", "test/options_test.rb", "test/retrying_http_test.rb", "test/startup_config_test.rb", "test/test_helper.rb", "test/url_shortener_test.rb", "test/util_test.rb"]
  s.homepage = %q{http://github.com/tuomas/tweetwine}
  s.rdoc_options = ["--title", "tweetwine 0.2.7", "--main", "README.rdoc", "--exclude", "test", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A simple Twitter agent for command line use}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 1.0.0"])
    else
      s.add_dependency(%q<rest-client>, [">= 1.0.0"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 1.0.0"])
  end
end
