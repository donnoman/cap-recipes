Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "git:install"
end
