Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "datadog:install"
  after "datadog:install", "datadog:setup"
  after "datadog:setup", "datadog:restart"
end
