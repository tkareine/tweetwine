# coding: utf-8

# Add lib dir to $LOAD_PATH so that `require 'tweetwine/version'`
# (executed in tests) loads the version file only once on MRI 1.8.7.
lib_dir = File.expand_path('lib', File.dirname(__FILE__))
$LOAD_PATH.unshift lib_dir unless $LOAD_PATH.include? lib_dir
require 'tweetwine/version'

Project = Struct.new('Project', :spec, :dirs, :extra).new(
  {
    :name         => 'tweetwine',
    :version      => Tweetwine.version.dup,
    :summary      => Tweetwine.summary,
    :description  => '',
    :email        => 'tkareine@gmail.com',
    :homepage     => 'https://github.com/tkareine/tweetwine',
    :authors      => ['Tuomas Kareinen']
  },
  {
    :man  => 'man',
    :rdoc => 'rdoc',
    :test => 'test'
  },
  {}
)

Project.spec[:description] = <<-END
A simple but tasty Twitter agent for command line use, designed for quickly
showing the latest tweets.
  END

Project.extra[:title] = "#{Project.spec[:name]} #{Project.spec[:version]}"
