# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "ruby:install"
  after "ruby:install", "ruby:rubygems_source_fix"
  after "ruby:install", "ruby:ruby_debugger"
  after "deploy:setup", "ruby:ensure_trust_github"
end
