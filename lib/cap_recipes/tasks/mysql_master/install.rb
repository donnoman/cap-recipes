Capistrano::Configuration.instance(true).load do

  namespace :mysql_master do
    roles[:mysql_master]
    roles[:mysql_slave]

    # mysql configuration sets
    set :mysql_bind_address, "127.0.0.1"
    set :mysql_listen_interface, "eth0"
    set :mysql_listen, "###ETH###"
    set(:mysql_repl_pass) { utilities.ask "mysql_repl_pass" }
    set :mysql_master_repl_conf, File.join(File.dirname(__FILE__),'replication.cnf')
    set :mysql_master_repl_conf_path, "/etc/mysql/conf.d/replication.cnf"
    set :mysql_server_conf, File.join(File.dirname(__FILE__),'my.cnf')
    set :mysql_server_conf_path, "/etc/mysql/my.cnf"
    set :mysql_storage_engine_conf, File.join(File.dirname(__FILE__),'default-storage-engine.cnf')
    set :mysql_storage_engine_conf_path, "/etc/mysql/conf.d/default-storage-engine.cnf"
    set :mysql_slave_repl_conf, File.join(File.dirname(__FILE__),'slave.cnf')
    set :mysql_slave_repl_conf_path, "/etc/mysql/conf.d/slave.cnf"

    # ssh repl configuration sets
    set :ssh_repl_key_path, "/home/repl/.ssh/"
    set(:ssh_repl_priv_key) { utilities.ask "ssh_repl_private_key" }
    set(:ssh_repl_pub_key) { utilities.ask "ssh_repl_public_key" }
    set(:ssh_repl_auth_keys) { utilities.ask "ssh_repl_authorized_keys" }

    desc "Setup All"
    task :setup, :roles => [:mysql_master, :mysql_slave] do
      mysql_master.install_master_repl_conf
      mysql_master.install_slave_repl_conf
      mysql_master.add_repl_user
      mysql_master.install_repl_keys
      mysql_master.grant_repl_mysql
      apparmor.setup
      mysql_master.restart
      autossh.install
      autossh.setup
    end

    def ipaddress(eth)
      %Q{`ifconfig #{eth} | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`}
    end

    desc "Upload replication config"
    task :install_master_repl_conf, :roles => :mysql_master do
      utilities.sudo_upload_template mysql_server_conf, mysql_server_conf_path, :mode => "644", :owner => 'root:root'
      utilities.sudo_upload_template mysql_master_repl_conf, mysql_master_repl_conf_path, :mode => "644", :owner => 'root:root'
      utilities.sudo_upload_template mysql_storage_engine_conf, mysql_storage_engine_conf_path, :mode => "644", :owner => 'root:root'
    end

    desc "Upload replication config"
    task :install_slave_repl_conf, :roles => :mysql_slave do
      utilities.sudo_upload_template mysql_server_conf, mysql_server_conf_path, :mode => "644", :owner => 'root:root'
      utilities.sudo_upload_template mysql_slave_repl_conf, mysql_slave_repl_conf_path, :mode => "644", :owner => 'root:root'
      utilities.sudo_upload_template mysql_storage_engine_conf, mysql_storage_engine_conf_path, :mode => "644", :owner => 'root:root'
    end

    desc "Add Replication user for AutoSSH"
    task :add_repl_user, :roles => [:mysql_master, :mysql_slave] do
      utilities.addgroup "repl", :system => true
      utilities.adduser "repl" , :group => "repl"
    end

    desc "Install repl ssh key files"
    task :install_repl_keys, :roles => [:mysql_master, :mysql_slave] do
      sudo "mkdir -p #{ssh_repl_key_path}"
      sudo "chmod 700 #{ssh_repl_key_path}"
      sudo "chown repl:repl #{ssh_repl_key_path}"
      utilities.sudo_upload_template ssh_repl_priv_key, "/home/repl/.ssh/id_rsa", :mode => "600", :owner => "repl:repl"
      utilities.sudo_upload_template ssh_repl_pub_key, "/home/repl/.ssh/id_rsa.pub", :mode => "640", :owner => "repl:repl"
      utilities.sudo_upload_template ssh_repl_auth_keys, "/home/repl/.ssh/authorized_keys", :mode => "640", :owner => "repl:repl"
    end

    desc "Grant the Replication User Access"
    task :grant_repl_mysql, :roles => [:mysql_master, :mysql_slave] do
      sudo %Q{mysql -uroot -e "GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO repl@'127.0.0.1' IDENTIFIED BY '#{mysql_repl_pass}';"}
      sudo %Q{mysql -uroot -e "FLUSH PRIVILEGES;"}
    end

    %w(start stop restart reload).each do |t|
    desc "#{t} mysql"
      task t.to_sym, :roles => [:mysql_master, :mysql_slave] do
        sudo "service mysql #{t}"
      end
    end

  end

end