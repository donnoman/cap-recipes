# @author Donovan Bray <donnoman@donovanbray.com>

Capistrano::Configuration.instance(true).load do

  after "deploy:provision", "hlds:install"
  after "hlds:install", "hlds:update", "hlds:setup"

end