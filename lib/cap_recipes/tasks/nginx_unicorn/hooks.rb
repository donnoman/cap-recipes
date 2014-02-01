# @author Donovan Bray <donnoman@donovanbray.com>

Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "nginx_unicorn:install"
  after "deploy:setup", "nginx_unicorn:setup"
  after "logrotate:rotate", "nginx_unicorn:reopen"
  after "sdagent:setup", "nginx_unicorn:setup_sdagent"
  after "nginx_unicorn:install", "nginx_unicorn:setup"
  after "nginx_unicorn:setup", "nginx_unicorn:configure"
  before "deploy:finalize_update", "nginx_unicorn:finalize_update"
  on :load, "nginx_unicorn:watcher"
end
