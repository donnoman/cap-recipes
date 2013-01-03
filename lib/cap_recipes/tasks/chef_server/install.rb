###############################################################################
# CHEF-SERVER INSTALL
################################################################################
require 'tempfile'

Capistrano::Configuration.instance(true).load do

  namespace :chef do
    namespace :server do
      roles[:chef_server]

      set(:chef_server_url) { "http://127.0.0.1:4000" }
      set(:chef_server_amqp_password) { "p@ssw0rd" }
      set(:chef_server_admin_password) { "p@ssw0rd" }
      set(:chef_server_install_script) { File.join(File.dirname(__FILE__), 'install.sh.erb') }

      # http://www.opscode.com/chef/download?v=&p=ubuntu&pv=10.04&m=x86_64
      set(:chef_server_omnibus_url) { "http://www.opscode.com/chef/install.sh" }

      set(:chef_server_dc3_version) { nil }
      set(:chef_server_dc3_platform) { "ubuntu" }
      set(:chef_server_dc3_platform_version) { "10.04" }
      set(:chef_server_dc3_machine_arch) { "x86_64" }

      set(:chef_server_config_template) { File.join(File.dirname(__FILE__), 'client.rb.erb') }
      set(:chef_server_config_log_level) { ":info" }
      set(:chef_server_config_log_location) { "STDOUT" }
      set(:chef_server_config_chef_server_url) { "http://127.0.0.1:4000" }
      set(:chef_server_config_ssl_verify_mode) { ":verify_none" }
      set(:chef_server_config_environment) { nil }
      set(:chef_server_config_validation_client_name) { "chef-validator" }
      set(:chef_server_config_file_backup_path) { "/var/chef/backup" }
      set(:chef_server_config_file_cache_path) { "/var/chef/cache" }
      set(:chef_server_install_method) { :ec2 }
      set(:chef_server_validation_pem_path) { nil }
      set(:chef_server_config_encrypted_data_bag_secret_path) { nil }

      desc "install chef-server"
      task :install, :roles => [:chef_server], :on_no_matching_servers => :continue do
        logger.info("#" * 80)
        logger.info("# CHEF-SERVER INSTALL")
        logger.info("#" * 80)

        # utilities.sudo_upload_template(chef_server_install_script, "/root/chef-server-install.sh", :mode => "554", :owner => "root:root")
        # sudo("/root/chef-server-install.sh")

        case chef_server_install_method.to_sym
        when :ec2 then
          run("curl -L http://www.opscode.com/chef/install.sh | #{sudo} bash")
          sudo("sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config")
          sudo("/etc/init.d/ssh stop")
          sudo("/etc/init.d/ssh start")
          sudo("rm -rfv /var/chef/cache/* /var/chef/backup/*")
        when :dc3 then
          chef_client_url_params = [
            "v=#{chef_client_dc3_version}",
            "p=#{chef_client_dc3_platform}",
            "pv=#{chef_client_dc3_platform_version}",
            "m=#{chef_client_dc3_machine_arch}"
          ]
          chef_client_url = "http://www.opscode.com/chef/download?" + chef_client_url_params.join('&')
          chef_client_tempfile = Tempfile.new("chef-server")
          utilities.stream_locally("wget \"#{chef_client_url}\" -O #{chef_client_tempfile.path}")
          utilities.sudo_upload(chef_client_tempfile.path, "/var/tmp/chef-client.deb")
          sudo("dpkg -i /var/tmp/chef-server.deb")
          sudo("ln -svf /opt/chef/bin/* /usr/bin/")
        end
      end

      desc "configure chef-server"
      task :configure, :roles => [:chef_server], :on_no_matching_servers => :continue do
        logger.info("#" * 80)
        logger.info("# CHEF-SERVER CONFIGURE")
        logger.info("#" * 80)

        sudo("mkdir -p /etc/chef/")

        chef_server_validation_pem = File.expand_path(File.join(chef_server_validation_pem_path, "chef-#{chef_server_install_method}-validation.pem"))
        utilities.sudo_upload(chef_server_validation_pem, "/etc/chef/validation.pem", :owner => "chef:chef", :mode => "0400")

        chef_client_config_encrypted_data_bag_secret = File.expand_path(File.join(chef_server_config_encrypted_data_bag_secret_path, "chef-#{chef_server_install_method}-data-bag-secret"))
        utilities.sudo_upload(chef_client_config_encrypted_data_bag_secret, "/etc/chef/encrypted_data_bag_secret", :owner => "chef:chef", :mode => "0400")

        utilities.sudo_upload_template(chef_server_config_template, "/etc/chef/client.rb", :owner => "chef:chef")

        sudo("chown -Rv chef:chef /etc/chef")
      end

      desc "chef-server bootstrap; runs chef-server once via command line"
      task :bootstrap, :roles => [:chef_server], :on_no_matching_servers => :continue do
        chef.client.stop
        find_servers_for_task(current_task).each do |server|
          logger.info("#" * 80)
          logger.info("# CHEF-SERVER BOOTSTRAP: #{server}")
          logger.info("#" * 80)

          sudo("bash -c '([[ -f /opt/chef/bin/chef-client ]] && /opt/chef/bin/chef-client) || echo \"NOOP\"'", :hosts => server)
          sudo("bash -c '([[ -f /etc/chef/client.pem ]] && chmod -v 0400 /etc/chef/client.pem) || echo \"NOOP\"'", :hosts => server)
          sudo("chown -Rv chef:chef /etc/chef", :hosts => server)
        end
        chef.client.start
      end

    end
  end

end
