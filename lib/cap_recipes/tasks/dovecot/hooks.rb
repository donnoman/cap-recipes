# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "dovecot:install"
  after "dovecot:install", "dovecot:setup"
  after "dovecot:setup", "dovecot:restart"
end
