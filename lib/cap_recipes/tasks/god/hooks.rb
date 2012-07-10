Capistrano::Configuration.instance(true).load do
  after "deploy:provision" , "god:clear_confd", "god:install"
  after "god:install", "god:setup"
  before "deploy:start", "god:setup"
  after "deploy:start", "god:start"
  before "deploy:restart", "god:setup"
  after "deploy:restart", "god:restart"
  after "god:setup", "god:contacts"
  on :load, "god:watcher"
end
