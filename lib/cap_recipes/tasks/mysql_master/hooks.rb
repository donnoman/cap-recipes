Capistrano::Configuration.instance(true).load do
  after  "mysql:install", "mysql_master:setup"
  after "mysql_master:setup", "mysql:restart"
end