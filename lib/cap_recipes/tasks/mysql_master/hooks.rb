Capistrano::Configuration.instance(true).load do
	#TODO Need to verify this
  after  "deploy:provision", "mysql:install"
  before "mysql:install", "mysql:install_client_libs"
  after  "mysql:install_client_libs", ",mysql_master:setup"
end