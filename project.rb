# coding: utf-8

name = 'tweetwine'
$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))
require "#{name}/version"

Project = Struct.new('Project', :spec, :dirs, :extra).new(
  {
    :name         => name,
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
