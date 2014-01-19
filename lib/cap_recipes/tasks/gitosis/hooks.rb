Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "gitosis:install"
  before "gitosis:setup_packages", "gitosis:cleanup"
  after "gitosis:setup_packages", "gitosis:cleanup"
  before "gitosis:copy_ssh", "gitosis:generate_ssh"
end
