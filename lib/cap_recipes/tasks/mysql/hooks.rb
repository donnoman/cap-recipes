Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "mysql:install"
  before "mysql:install", "mysql:install_client_libs"
  #after "mysql:install", "mysql:restart"
end
