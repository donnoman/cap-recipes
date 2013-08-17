# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do
  after "deploy:update_code", "resque:configure"
  before "deploy", "resque:workers:stop"
  after "deploy:restart", "resque:workers:start"
  after "deploy:start", "resque:workers:start"
  after "resque:workers:stop", "resque:workers:force_stop"
  on :load, "resque:watcher"
end
