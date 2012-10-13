Capistrano::Configuration.instance(true).load do
  # after "deploy:provision", "chef_server:install"
  after "chef_server:install", "chef_server:setup"
  # after "chef_server:setup", "chef_server:logrotate"
end
