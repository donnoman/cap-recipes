# @author Donovan Bray <donnoman@donovanbray.com>

Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "bprobe:install"
  on :load, "bprobe:watcher"
end
