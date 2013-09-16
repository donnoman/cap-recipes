# @author Donovan Bray <donnoman@donovanbray.com>

Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "nginx:install"
  after "deploy:setup", "nginx:setup"
  after "logrotate:rotate", "nginx:reopen"
  after "sdagent:setup", "nginx:setup_sdagent"
  after "nginx:install", "nginx:setup", "nginx:configure"
  after "nginx:configure", "nginx:upload_certs"
  before "nginx:configure", "nginx:verify_cert_pairs"
  on :load, "nginx:watcher"
end
