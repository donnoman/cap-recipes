# @author Donovan Bray <donnoman@donovanbray.com>

Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "java_7_oracle:install"
end
