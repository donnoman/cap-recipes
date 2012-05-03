Capistrano::Configuration.instance(true).load do
  after "deploy:provision" , "dphys_swapfile:install"
end
