# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do
  before "bundler:configure", "bundler:install"
  before "deploy:finalize_update", "bundler:configure"
  after "deploy:provision", "bundler:install"
  after "deploy:restart", "bundler:save_bundle"
end
