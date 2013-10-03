Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "nrpe:install"
  after "nrpe:install", "nrpe:setup", "nrpe:restart"
end
