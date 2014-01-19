# @author Donovan Bray <donnoman@donovanbray.com>

Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "jenkins:install"
  after "jenkins:install", "jenkins_jnlp_slave:install"
end
