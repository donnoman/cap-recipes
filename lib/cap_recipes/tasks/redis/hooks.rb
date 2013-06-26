Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "redis:install"
  after "redis:install", "redis:setup"
  # after "redis:setup", "redis:cli_helper"
  after "redis:setup", "redis:logrotate"
  on :load, "redis:watcher"
end
