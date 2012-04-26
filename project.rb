# coding: utf-8

# Add lib dir to $LOAD_PATH so that `require 'tweetwine/version'`
# (executed in tests) loads the version file only once on MRI 1.8.7.
lib_dir = File.expand_path('lib', File.dirname(__FILE__))
$LOAD_PATH.unshift lib_dir unless $LOAD_PATH.include? lib_dir
require 'tweetwine/version'

name = 'tweetwine'
version = Tweetwine.version.dup

Project = {
  :spec => {
    :name         => name,
    :version      => version,
    :summary      => Tweetwine.summary,
    :description  => 'A simple but tasty Twitter agent for command line use, designed for quickly\nshowing the latest tweets.',
    :email        => 'tkareine@gmail.com',
    :homepage     => 'https://github.com/tkareine/tweetwine',
    :authors      => ['Tuomas Kareinen']
  },
  :extra => {
    :title => "#{name} #{version}"
  },
  :dir => {
    :man  => 'man',
    :rdoc => 'rdoc',
    :test => 'test'
  }
}
