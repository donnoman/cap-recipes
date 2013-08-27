Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "stingray:install"
  after "stingray:install", "stingray:setup"
end
