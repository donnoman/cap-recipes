# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'cap_recipes/version'

Gem::Specification.new do |s|
  s.name          = "cap-recipes"
  s.version       = Cap::Recipes::VERSION
  s.authors       = ["Nathan Esquenazi", "Donovan Bray"]
  s.email         = ["donovan@homerun.com"]
  s.homepage      = "https://github.com//cap-recipes"
  s.summary       = "capistrano 2 provisioning recipes"
  s.description   = "Battle-tested capistrano provisioning recipes for debian based distributions"
  s.files         = `git ls-files app lib`.split("\n")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.rubyforge_project = '[none]'
end
