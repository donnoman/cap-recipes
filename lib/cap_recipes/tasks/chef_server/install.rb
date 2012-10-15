###############################################################################
# CHEF-SERVER INSTALL
################################################################################
Capistrano::Configuration.instance(true).load do

  namespace :chef do
    namespace :server do

      roles[:chef_server]

      set(:chef_server_url) { "http://127.0.0.1:4000" }
      set(:chef_server_amqp_password) { "p@ssw0rd" }
      set(:chef_server_admin_password) { "p@ssw0rd" }
      set(:chef_server_install_script) { File.join(File.dirname(__FILE__), 'install.sh.erb') }

      desc "install chef-server"
      task :install, :roles => [:chef_server] do
        utilities.sudo_upload_template(chef_server_install_script, "/root/chef-server-install.sh", :mode => "554", :owner => "root:root")
        sudo("/root/chef-server-install.sh")
      end

      desc "update chef-server"
      task :update, :roles => [:chef_server] do
      end

    end
  end

end
