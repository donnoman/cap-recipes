# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do
  after "deploy:provision" , "unicorn:install"
  after "deploy:start",   "unicorn:start"
  after "deploy:stop",    "unicorn:stop"
  after "deploy:restart", "unicorn:restart"
  before "deploy:start", "unicorn:configure"
  before "deploy:restart", "unicorn:configure"
  on :load, "unicorn:watcher"
end
