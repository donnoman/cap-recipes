###############################################################################
# CHEF-CLIENT HOOKS
################################################################################
Capistrano::Configuration.instance(true).load do

  # DEPLOY
  # after "deploy:stop", "chef:client:stop"
  # after "deploy:start", "chef:client:start"
  # after "deploy:restart", "chef:client:restart"
  # after "deploy:provision", "chef:client:install"
  # after "deploy:update", "chef:client:update"

  # CHEF-CLIENT
  # after "chef:client:install", "chef:client:configure"
  # after "chef:client:configure", "chef:client:bootstrap"
  # after "chef:client:bootstrap", "chef:client:status"

  after "chef:client:stop", "chef:client:status"
  after "chef:client:start", "chef:client:status"
  after "chef:client:restart", "chef:client:status"

end
