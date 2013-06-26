Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "monit:install"
  after "deploy:restart", "monit:enable", "monit:restart"
end
