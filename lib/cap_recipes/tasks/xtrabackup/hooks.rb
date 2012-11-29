# @author Rick Russell <sysadmin.rick@gmail.com>
Capistrano::Configuration.instance(true).load do  
  after "mysql:install", "percona:setup"
end