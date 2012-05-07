# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "denyhosts:install"
  after "denyhosts:install", "denyhosts:setup"
end
