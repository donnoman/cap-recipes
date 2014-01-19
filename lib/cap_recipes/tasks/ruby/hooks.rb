Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "ruby:install"
end
