Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "postgres:install"
  before "postgres:install", "postgres:install_client_libs"
  after "postgres:install", "postgres:setup"
  after "postgres:setup", "postgres:restart"
end
