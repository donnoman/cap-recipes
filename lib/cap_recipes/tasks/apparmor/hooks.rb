Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "apparmor:install"
  after "apparmor:install", "apparmor:setup"
  after "apparmor:setup", "apparmor:restart"
end
