Capistrano::Configuration.instance(true).load do
  before "mysql_master:setup", "apparmor:setup"
end