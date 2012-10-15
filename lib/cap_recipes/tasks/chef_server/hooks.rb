###############################################################################
# CHEF-SERVER HOOKS
################################################################################
Capistrano::Configuration.instance(true).load do

  # DEPLOY
  after "deploy:provision", "chef:server:install"

  # CHEF-SERVER
  after "chef:server:install", "chef:server:update"
  # after "chef:server:update", "chef_server:logrotate"

end
