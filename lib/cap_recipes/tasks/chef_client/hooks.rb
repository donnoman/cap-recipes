###############################################################################
# CHEF-CLIENT HOOKS
################################################################################
Capistrano::Configuration.instance(true).load do

  # DEPLOY
  after "deploy:stop", "chef:client:stop"
  after "deploy:start", "chef:client:start"
  after "deploy:restart", "chef:client:restart"
  #after "deploy:provision", "chef:client:install"
  after "deploy:update", "chef:client:update"

  # CHEF-CLIENT
  after "chef:client:install", "chef:client:update"
  # after "chef:client:update", "chef:client:logrotate"

end
