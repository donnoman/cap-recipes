# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do
  before "bundler:configure", "bundler:install"
  after "deploy:update_code", "bundler:configure"
  after "deploy:provision", "bundler:install"
  after "deploy:restart", "bundler:save_bundle"
end
