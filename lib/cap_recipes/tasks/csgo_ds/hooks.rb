# @author Rick Russell <sysadmin.rick@gmail.com>

Capistrano::Configuration.instance(true).load do

  after "deploy:provision", "csgo_ds:install_steamcmd"
#  after "csgo_ds:install_steamcmd", "csgo_ds:install_csgo"
#  after "csgo_ds:install_csgo", "csgo_ds:setup"

end