# @author Rick Russell <sysadmin.rick@gmail.com>

Capistrano::Configuration.instance(true).load do

  namespace :percona do 
    roles[:mysqld_backup]
    set(:percona_backup_target) { "#{mysql_data_dir}"}
    set(:percona_backup_destination) { "#{mysql_backup_location}" }
    set :mysql_percona_apt_list, File.join(File.dirname(__FILE__),'percona.list')
    set :mysql_percona_apt_list_path, "/etc/apt/sources.list.d/percona.list"
    set(:mysql_percona_user) {secrets.percona[:database_user]}
    set(:mysql_percona_pass) {secrets.percona[:database_user_password]}
    set :mysql_backup_script, File.join(File.dirname(__FILE__),'innobackupex-full.sh.erb')
    set :mysql_backup_script_path, "/etc/init.d/innobackupex-full"
    set :mysql_restore_script, File.join(File.dirname(__FILE__),'innobackupex-restore.sh.erb')
    set :mysql_restore_script_path, "/etc/init.d/innobackupex-restore"
    # Sane Defaults
    set :mysql_data_dir, "/var/lib/mysql"
    set :mysql_backup_location, "/opt/mysql_backups"
    set :mysql_innodb_buffer_pool_size, "256MB"
    set :mysql_listen_interface, "eth0"

    def ipaddress(eth)
      %Q{`ifconfig #{eth} | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`}
    end

    # percona.innobackupex [Use innobackupex when a mix of MyISAM and InnoDB]
    def innobackupex(options={})
      switches = ""
      switches += " --apply-log" if options[:apply_log]
      switches += " --compress" if options[:compress]
      switches += " --export" if options[:export]
      switches += " --incremental" if options[:incremental]
      switches += " --slave-info" if options[:slave_info]
      switches += " --version" if options[:version]
      switches += " --safe-slave-backup" if options[:safe_slave_backup]
      switches += " --user=#{options[:user]} " unless options[:user].nil?
      switches += " --host=#{options[:host]} " unless options[:host].nil?
      switches += " --port=#{options[:port]} " unless options[:port].nil?
      switches += " --password=#{options[:password]} " unless options[:password].nil?
      switches += " --parallel=#{options[:parallel]} " unless options[:parallel].nil?
      switches += " --tmpdir=#{options[:tmpdir]} " unless options[:tmpdir].nil?
      switches += " --throttle=#{options[:throttle]} " unless options[:throttle].nil?
      switches += " --databases=#{options[:databases]} " unless options[:databases].nil?
      switches += " --compress-threads=#{options[:compress_threads]} " unless options[:compress_threads].nil?
      switches += " --incremental-dir=#{options[:incremental_dir]} " unless options[:incremental_dir].nil? # Combined dir for incremental and base to be combined
      switches += " --incremental-basedir=#{options[:incremental_basedir]} " unless options[:incremental_basedir].nil? # Base dir for incremental backup 
      invoke_command "sudo innobackupex #{switches}",
      :via => run_method
    end

    # percona.xtrabackup [Use xtrabackup with InnoDB only]
    def xtrabackup(options={})
      switches = ""
      switches += " --backup" if options[:backup]
      switches += " --prepare" if options[:prepare]
      switches += " --datadir=#{options[:datadir]} " unless options[:datadir].nil?
      switches += " --target=#{options[:target]} " unless options[:target].nil?
      switches += " --tmpdir=#{options[:tmpdir]} " unless options[:tmpdir].nil?
      switches += " --throttle=#{options[:throttle]}  " unless options[:throttle].nil?
      switches += " --use-memory=#{options[:memory]} " unless options[:memory].nil?
      switches += " --incremental-basedir=#{options[:incremental_basedir]} " unless options[:incremental_basedir].nil?
      invoke_command "sudo xtrabackup #{switches}",
      :via => run_method
    end

    desc "Install and Setup Xtrabackup Tools, Users and Scripts"
    task :setup, :roles => :mysqld_backup do
      percona.install_xtrabackup
      percona.upload_backup_script
      percona.grant_percona_user
    end

    desc "Install Percona XtraBackup"
    task :install_xtrabackup, :roles => :mysqld_backup do
       run "#{sudo} gpg --keyserver hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A && #{sudo} gpg -a --export CD2EFD2A | #{sudo} apt-key add -"
       utilities.sudo_upload_template mysql_percona_apt_list, mysql_percona_apt_list_path, :mode => "644", :owner => 'root:root'
       utilities.apt_update
       utilities.apt_install "xtrabackup"
     end

      desc "Transfer backup scripts to host"
      task :upload_backup_script, :roles => :mysqld_backup do
        run "#{sudo} mkdir -p /root/script"
        utilities.apt_install "at lbzip2" 
        utilities.sudo_upload_template mysql_backup_script, mysql_backup_script_path, :mode => "655", :owner => 'root:root'
        utilities.sudo_upload_template mysql_restore_script, mysql_restore_script_path, :mode => "655", :owner => 'root:root'
      end

    desc "Grant the Percona user permissions"
    task :grant_percona_user, :roles => :mysqld_backup do
      mysqld_listen_ip = capture("echo #{ipaddress(mysql_listen_interface)}", :roles => :mysqld_backup).chomp
      sudo %Q{mysql -uroot -e "GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO '#{mysql_percona_user}'@'#{mysqld_listen_ip}' IDENTIFIED BY '#{mysql_percona_pass}';"}
      sudo %Q{mysql -uroot -e "FLUSH PRIVILEGES"}
    end

    desc "Revoke the Percona permissions"
    task :revoke_percona_user, :roles => :mysqld_backup do
      mysqld_listen_ip = capture("echo #{ipaddress(mysql_listen_interface)}", :roles => :mysqld_backup).chomp
      sudo %Q{mysql -uroot -e "REVOKE RELOAD, LOCK TABLES, REPLICATION CLIENT, REPLICATION SLAVE ON *.* FROM '#{mysql_percona_user}'@'#{mysqld_listen_ip}' IDENTIFIED BY '#{mysql_percona_pass}';"}
      sudo %Q{mysql -uroot -e "FLUSH PRIVILEGES"}
    end

    namespace :backup do
      
      namespace :innobackupex do

        # Create Full Innobackupex Backup
        desc "Create Full Innobackupex Backup using Percona innobackupex"
        task :create_full_master, :roles => :mysqld_backup do
          percona.revoke_percona_user
          percona.grant_percona_user
          run "#{sudo} mkdir -p #{percona_backup_destination}"
          mysql_remote_host = capture("hostname -f || hostname", :roles => :mysql_master).chomp
          run "#{sudo} innobackupex --user=#{mysql_percona_user} --password=#{mysql_percona_pass} --slave-info --host=#{mysql_remote_host} --parallel=10 #{percona_backup_destination}"
          # Capistrano blew up on this @ :parallel => "10",
          # percona.innobackupex :user => '#{mysql_percona_user}', :password => '#{mysql_percona_pass}', :slave_info => true, :parallel => "10", '#{percona_backup_destination}'
        end

        desc "Prepare innobackupex backup"
        task :prepare_backup, :roles => :mysqld_backup do
          percona.revoke_percona_user
          percona.grant_percona_user
          percona.innobackupex :apply_log, "#{percona_backup_destination}"
        end

        #TODO Add Restore Tasks

      end

      namespace :xtrabackup do

        # Prepare xtrabackup backup locations
        desc "Prepare Percona XtraBackup locations"
        task :prepare_target, :roles => :mysqld_backup do
          sudo "rm -rf #{percona_backup_destination}/old_full"
          sudo "mv #{percona_backup_destination}/full_backup #{percona_backup_destination}/old_full"
          sudo "mkdir -p #{percona_backup_destination}/full_backup"
          sudo "mkdir -p #{percona_backup_destination}/combined_incremental"
          sudo "mkdir -p #{percona_backup_destination}/newest_incremental"
        end

        # Create Full Xtrabackup Backup 
        desc "Create Full Xtrabackup Backup using Percona xtrabackup"
        task :create_full, :roles => :mysqld_backup do
          percona.revoke_percona_user
          percona.grant_percona_user
          percona.backup.xtrabackup.prepare_target
          percona.xtrabackup :backup => true, :datadir => "'#{percona_backup_target}'", :target => "'#{percona_backup_destination}/full_backup'", :memory => "'#{mysql_innodb_buffer_pool_size}'"
        end

        # Prepare(twice for good measure).
        desc "Prepare Xtrabackup backup"
        task :prepare_full, :roles => :mysqld_xtrabackup do
          percona.xtrabackup :prepare => true, :target => "'#{percona_backup_destination}/full_backup'" 
          percona.xtrabackup :prepare => true, :target => "'#{percona_backup_destination}/full_backup'"
        end

        # Remember you need a Full Backup Created First!
        desc "Create an Incremental Backup using Percona XtraBackup"
        task :create_primary_incremental, :roles => :mysqld_backup do
          # Prepare backup locations
          percona.backup.prepare_target 
          percona.xtrabackup :backup => true, :target => "#{percona_backup_destination}/combined_incremental", :incremental_basedir => "#{percona_backup_destination}/full_backup"
        end

        # Remember you need a Full Backup Created First!
        desc "Create an Incremental Backup using Percona XtraBackup"
        task :create_secondary_incremental, :roles => :mysqld_backup do
          percona.xtrabackup :backup => true, :target => "#{percona_backup_destination}/newest_incremental", :incremental_basedir => "#{percona_backup_destination}/combined_incremental"
        end

        #TODO Add Restore Tasks

      end

    end

  end

end