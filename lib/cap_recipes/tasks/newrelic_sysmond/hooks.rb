# @author Donovan Bray <donnoman@donovanbray.com>

Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "newrelic_sysmond:install"
  after "newrelic_sysmond:install", "newrelic_sysmond:setup"
  after "newrelic_sysmond:setup", "newrelic_symond:restart"
  on :load, "newrelic_sysmond:watcher"
end
