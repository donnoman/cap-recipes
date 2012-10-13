Capistrano::Configuration.instance(true).load do
  # after "deploy:provision", "chef_client:install"
  after "chef_client:install", "chef_client:setup"
  # after "chef_client:setup", "chef_client:logrotate"
end
