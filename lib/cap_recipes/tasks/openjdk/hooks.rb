# @author Donovan Bray <donnoman@donovanbray.com>

Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "openjdk:install"
end
