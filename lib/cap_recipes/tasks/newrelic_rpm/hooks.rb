# @author Donovan Bray <donnoman@donovanbray.com>

Capistrano::Configuration.instance(true).load do
  after "deploy:restart", "newrelic_rpm:notice_deployment"
  after "deploy:start", "newrelic_rpm:notice_deployment"
end
