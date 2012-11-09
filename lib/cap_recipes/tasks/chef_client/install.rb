require 'tempfile'

###############################################################################
# CHEF-CLIENT INSTALL
################################################################################
Capistrano::Configuration.instance(true).load do

  namespace :chef do
    namespace :client do
      roles[:chef_client]

      # http://www.opscode.com/chef/download?v=&p=ubuntu&pv=10.04&m=x86_64
      set(:chef_client_omnibus_url) { "http://www.opscode.com/chef/install.sh" }

      set(:chef_client_dc3_version) { nil }
      set(:chef_client_dc3_platform) { "ubuntu" }
      set(:chef_client_dc3_platform_version) { "10.04" }
      set(:chef_client_dc3_machine_arch) { "x86_64" }

      set(:chef_client_config_template) { File.join(File.dirname(__FILE__), 'client.rb.erb') }
      set(:chef_client_config_log_level) { ":debug" }
      set(:chef_client_config_log_location) { "STDOUT" }
      set(:chef_client_config_chef_server_url) { nil }
      set(:chef_client_config_ssl_verify_mode) { ":verify_none" }
      set(:chef_client_config_validation_client_name) { "chef-validator" }
      set(:chef_client_config_environment) { rails_env.to_s }
      set(:chef_client_install_method) { :ec2 }

      desc "install chef-client"
      task :install, :roles => [:chef_client], :on_no_matching_servers => :continue do
        case chef_client_install_method.to_sym
        when :ec2 then
          run("curl -L http://www.opscode.com/chef/install.sh | #{sudo} bash")
        when :dc3 then
          chef_client_url_params = [
            "v=#{chef_client_dc3_version}",
            "p=#{chef_client_dc3_platform}",
            "pv=#{chef_client_dc3_platform_version}",
            "m=#{chef_client_dc3_machine_arch}"
          ]
          chef_client_url = "http://www.opscode.com/chef/download?" + chef_client_url_params.join('&')
          chef_client_tempfile = Tempfile.new("chef-client")
          utilities.stream_locally("wget \"#{chef_client_url}\" -O #{chef_client_tempfile.path}")
          utilities.sudo_upload(chef_client_tempfile.path, "/var/tmp/chef-client.deb")
          sudo("dpkg -i /var/tmp/chef-client.deb")
          sudo("ln -svf /opt/chef/bin/* /usr/bin/")
        end
        sudo("mkdir -p /etc/chef/")
        utilities.sudo_upload(chef_server_validation_pem, "/etc/chef/validation.pem", :owner => "root:root")
      end

      desc "update chef-client"
      task :update, :roles => [:chef_client], :on_no_matching_servers => :continue do
        utilities.sudo_upload_template(chef_client_config_template, "/etc/chef/client.rb", :owner => "root:root")
      end

    end
  end

end
