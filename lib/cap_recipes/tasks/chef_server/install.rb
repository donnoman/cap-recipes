Capistrano::Configuration.instance(true).load do
  namespace :chef_server do
    roles[:chef_server]

    set(:chef_server_omnibus_url) { "http://www.opscode.com/chef/install.sh" }
    set(:chef_server_url) { "http://127.0.0.1:4000" }
    set(:chef_server_amqp_password) { "p@ssw0rd" }
    set(:chef_server_admin_password) { "p@ssw0rd" }
    set(:chef_server_install_script) { File.join(File.dirname(__FILE__), 'install.sh.erb') }

    desc "install chef-server"
    task :install, :roles => [:chef_server] do
      utilities.sudo_upload_template(chef_server_install_script, "/root/chef-server-install.sh", :mode => "554", :owner => "root:root")
      sudo("/root/chef-server-install.sh")
    end

    desc "setup chef-server"
    task :setup, :roles => [:chef_server] do
    end

  end
end
