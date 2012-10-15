###############################################################################
# CHEF-CLIENT INSTALL
################################################################################
Capistrano::Configuration.instance(true).load do

  namespace :chef do
    namespace :client do

      roles[:chef_client]

      set(:chef_client_omnibus_url) { "http://www.opscode.com/chef/install.sh" }

      desc "install chef-client"
      task :install, :roles => [:chef_client], :on_error => :continue,  :on_no_matching_servers => :continue do
        run("curl -L #{chef_client_omnibus_url} | #{sudo} bash")
      end

      desc "update chef-client"
      task :update, :roles => [:chef_client],  :on_no_matching_servers => :continue do
      end

    end
  end

end
