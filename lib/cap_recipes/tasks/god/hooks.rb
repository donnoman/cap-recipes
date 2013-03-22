Capistrano::Configuration.instance(true).load do
  after "deploy:provision" , "god:clear_confd", "god:install"
  before "deploy:start", "god:setup"
  before "god:setup", "god:install_check"
  after "deploy:start", "god:start"
  before "deploy:restart", "god:setup"
  after "deploy:restart", "god:restart"
  after "god:setup", "god:contacts"
  on :load, "god:watcher"
end
