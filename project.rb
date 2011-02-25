# coding: utf-8

require 'ostruct'

name = 'tweetwine'
$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))
require "#{name}/version"

Project = OpenStruct.new({
  :name         => name,
  :version      => Tweetwine.version.dup,
  :summary      => Tweetwine.summary,
  :description  => '',
  :email        => 'tkareine@gmail.com',
  :homepage     => 'https://github.com/tkareine/tweetwine',
  :authors      => ['Tuomas Kareinen'],
  :dirs         => OpenStruct.new({
    :man  => 'man',
    :rdoc => 'rdoc',
    :test => 'test'
  }).freeze
})

Project.description = <<-END
A simple but tasty Twitter agent for command line use, designed for quickly
showing the latest tweets.
  END
Project.title = "#{Project.name} #{Project.version}"

Project.freeze
