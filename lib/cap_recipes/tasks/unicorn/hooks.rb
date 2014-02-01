# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do
  before "deploy:start", "unicorn:configure"
  before "deploy:restart", "unicorn:configure"
  after "deploy:start",   "unicorn:start"
  after "deploy:stop",    "unicorn:stop"
  after "deploy:restart", "unicorn:restart"
  before "deploy:finalize_update", "unicorn:finalize_update"
  on :load, "unicorn:watcher"
end
