Capistrano::Configuration.instance(true).load do

  namespace :autossh do
  	roles[:autossh]
    roles[:autossh_slave] #not all mysql slaves should be autossh'd
    roles[:autossh_master] #not all mysql masters should be autossh'd
    set :autossh_init, File.join(File.dirname(__FILE__),'autossh.sh')
    set(:autossh_default_remote_user) { utitlies.ask("autossh_default_remote_user") }
    set(:autossh_default_remote_host) { utitlies.ask("autossh_default_remote_host") }
    set(:autossh_default_remote_private_key) { utitlies.ask("autossh_default_remote_private_key") }
    set(:autossh_default_remote_public_key) { utitlies.ask("autossh_default_remote_public_key") }
    set(:autossh_default_remote_private_key_location) { utitlies.ask("autossh_default_remote_private_key_location") }
    set(:autossh_default_remote_public_key_location){ utitlies.ask("autossh_default_remote_public_key_location") }
    set(:autossh_default_remote_target_host) { utitlies.ask("autossh_default_remote_target_host") }
    set :autossh_default_remote_target_port, "3306"
    set :autossh_default_port, "3305"
    set :autossh_default_monitoring_port, "5122"
    set :autossh_default_name, "autossh"
    set(:autossh_layout) {
      []
    }

    def ipaddress(eth)
      %Q{`ifconfig #{eth} | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`}
    end

    on :start, :only => "deploy:provision" do
      autossh.install
    end

    desc "install autossh"
    task :install, :roles => [:autossh,:autossh_slave,:autossh_master] do
        utilities.apt_install "autossh"
    end

    desc "setup autossh"
    task :setup do
      autossh.setup_layout
      # autossh.setup_master
      # autossh.setup_slave
    end

    desc "Setup and Configure AutoSSH for master"
    task :setup_layout, :roles => :autossh do
      with_layout do
        utilities.sudo_upload_template autossh_init, "/etc/init.d/#{autossh_name}",  :mode => "755", :owner => 'root:root'
        sudo "update-rc.d -f #{autossh_name} defaults"
      end
    end

    #TODO the mysql based ones need to be refactored

    # desc "Setup and Configure AutoSSH for master"
    # task :setup_master, :roles => :autossh_master do
    #   mysql_slave_internal_ip = capture("echo #{ipaddress(autossh_eth)}", :roles => :mysql_slave).chomp
    #   mysql_autossh_remote_host = capture("hostname -f || hostname", :roles => :mysql_slave).chomp
    #   utilities.sudo_upload_template autossh_init, "/etc/init.d/autossh",  :mode => "755", :owner => 'root:root', :roles => :mysql_master
    #   sudo "sed -i s/##AUTOSSH_REMOTE##/#{mysql_autossh_remote_host}/g /etc/init.d/autossh"
    #   sudo "sed -i s/##AUTOSSH_TARGET##/#{mysql_slave_internal_ip}/g /etc/init.d/autossh"
    #   utilities.run_compressed %Q{
    #     #{sudo} chown root:root /etc/init.d/autossh;
    #     #{sudo} chmod 0644 /etc/init.d/autossh;
    #   }
    # end

    # desc "Setup and Configure AutoSSH for slave"
    # task :setup_slave, :roles => :autossh_slave do
    #   mysql_master_internal_ip = capture("echo #{ipaddress(autossh_eth)}", :roles => :mysql_master).chomp
    #   mysql_autossh_remote_host = capture("hostname -f || hostname", :roles => :mysql_master).chomp
    #   utilities.sudo_upload_template autossh_init, "/etc/init.d/autossh",  :mode => "755", :owner => 'root:root', :roles => :mysql_slave
    #   sudo "sed -i s/##AUTOSSH_REMOTE##/#{mysql_autossh_remote_host}/g /etc/init.d/autossh"
    #   sudo "sed -i s/##AUTOSSH_TARGET##/#{mysql_master_internal_ip}/g /etc/init.d/autossh"
    #   utilities.run_compressed %Q{
    #     #{sudo} chown root:root /etc/init.d/autossh;
    #     #{sudo} chmod 0644 /etc/init.d/autossh;
    #   }
    # end

    %w(start stop restart).each do |t|
      desc "#{t} Autossh"
      task t.to_sym, :roles => [:autossh,:autossh_slave,:autossh_master] do
        with_layout do
          sudo "/etc/init.d/#{autossh_name} #{t}"
        end
      end
    end

    def with_layout
      autossh_layout.each do |layout|
        set :autossh_name,                        layout[:name]                         || autossh_default_name
        set :autossh_remote_user,                 layout[:remote_user]                  || autossh_default_remote_user
        set :autossh_remote_host,                 layout[:remote_host]                  || autossh_default_remote_host
        set :autossh_remote_target_host,          layout[:remote_target_host]           || autossh_default_remote_target_host
        set :autossh_remote_target_port,          layout[:remote_target_port]           || autossh_default_remote_target_port
        set :autossh_port,                        layout[:port]                         || autossh_default_port
        set :autossh_monitoring_port,             layout[:monitoring_port]              || autossh_default_monitoring_port
        set :autossh_remote_private_key,          layout[:remote_private_key]           || autossh_default_remote_private_key
        set :autossh_remote_private_key_location, layout[:remote_private_key_location]  || autossh_default_remote_private_key_location
        set :autossh_remote_public_key,           layout[:remote_public_key]            || autossh_default_remote_public_key
        set :autossh_remote_public_key_location,  layout[:remote_public_key_location]   || autossh_default_remote_public_key_location
        yield layout if block_given?
      end
    end

  end

end
