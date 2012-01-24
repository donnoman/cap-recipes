Capistrano::Configuration.instance(true).load do

  namespace :autossh do
  	roles[:autossh]
    set :autossh_init, File.join(File.dirname(__FILE__),'autossh.sh')
    set :autossh_eth, "eth0"

    def ipaddress(eth)
      %Q{`ifconfig #{eth} | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`}
    end

    on :start, :only => "deploy:provision" do
      autossh.install
    end

    desc "Grandfather install task list"
    task :install, :roles => :autossh do
      autossh.install_autossh
    end

    desc "Grandfather setup task list"
    task :setup, :roles => :autossh do
      autossh.setup_master
      autossh.setup_slave
    end

    desc "Install autossh from apt"
    task :install_autossh, :roles => :autossh do
      utilities.apt_install "autossh"
    end

    desc "Setup and Configure AutoSSH for master"
    task :setup_master, :roles => :mysql_master do
      mysql_slave_internal_ip = capture("echo #{ipaddress(autossh_eth)}", :roles => :mysql_slave).chomp
      mysql_autossh_remote_host = capture("hostname -f || hostname", :roles => :mysql_slave).chomp
      utilities.sudo_upload_template autossh_init, "/etc/init.d/autossh",  :mode => "755", :owner => 'root:root', :roles => :mysql_master
      sudo "sed -i s/##AUTOSSH_REMOTE##/#{mysql_autossh_remote_host}/g /etc/init.d/autossh"
      sudo "sed -i s/##MASTER##/#{mysql_slave_internal_ip}/g /etc/init.d/autossh"
      utilities.run_compressed %Q{
        #{sudo} chown root:root /etc/init.d/autossh;
        #{sudo} chmod 0644 /etc/init.d/autossh;
      }
    end

    desc "Setup and Configure AutoSSH for slave"
    task :setup_slave, :roles => :mysql_slave do
      mysql_master_internal_ip = capture("echo #{ipaddress(autossh_eth)}", :roles => :mysql_master).chomp
      mysql_autossh_remote_host = capture("hostname -f || hostname", :roles => :mysql_master).chomp
      utilities.sudo_upload_template autossh_init, "/etc/init.d/autossh",  :mode => "755", :owner => 'root:root', :roles => :mysql_slave
      sudo "sed -i s/##AUTOSSH_REMOTE##/#{mysql_autossh_remote_host}/g /etc/init.d/autossh"
      sudo "sed -i s/##MASTER##/#{mysql_master_internal_ip}/g /etc/init.d/autossh"
      utilities.run_compressed %Q{
        #{sudo} chown root:root /etc/init.d/autossh;
        #{sudo} chmod 0644 /etc/init.d/autossh;
      }
    end

    desc "Start Autossh"
    task :start, :roles => :autossh do
      utilities.run_compressed %Q{
        #{sudo} /etc/init.d/autossh start
      }
    end

  end

end