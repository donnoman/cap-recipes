Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "stingray:install"
end
