Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "geoip:install"
end
