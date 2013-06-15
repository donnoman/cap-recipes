Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "postfix:install"
end
