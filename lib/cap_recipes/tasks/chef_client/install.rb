Capistrano::Configuration.instance(true).load do
  namespace :chef_client do
    roles[:chef_client]

    set(:chef_client_omnibus_url) { "http://www.opscode.com/chef/install.sh" }

    desc "install chef-client"
    task :install, :roles => [:chef_client] do
      sudo("curl -L #{chef_client_omnibus_url} | sudo bash")
    end

    desc "setup chef-client"
    task :setup, :roles => [:chef_client] do
    end

  end
end
