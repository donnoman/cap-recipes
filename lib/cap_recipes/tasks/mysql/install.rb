# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :mysql do
    roles[:mysqld]
    roles[:mysqld_backup]
    set(:mysql_admin_password) { utilities.ask "mysql_admin_password:"}
    set :mysql_restore_table_priorities, nil
    set :mysql_restore_source_name, nil

    set :mysql_backup_script, File.join(File.dirname(__FILE__),'mysql_backup_s3.sh')
    set :mysql_backup_script_path, "/root/script/mysql_backup.sh"
    set :mysql_restore_script, File.join(File.dirname(__FILE__),'mysql_restore.sh')
    set :mysql_restore_script_path, "/root/script/mysql_restore.sh"

    set :mysql_backup_archive_watermark, "0m"
    set :mysql_backup_s3_bucket, "mysql-backups"
    set :mysql_backup_log_path, "/tmp/mysql_backup.log"
    set(:mysql_backup_log_dest) {File.join(utilities.caproot,'log','backups')}
    set :mysql_backup_stop_sql_thread, false

    set :mysql_backup_chunk_size, "250M"
    set :mysql_backup_location, "/mnt/mysql_backups"
    set :mysql_bind_address, "127.0.0.1" # "0.0.0.0" for all interfaces.

    set :mysql_conf, File.join(File.dirname(__FILE__),'my.cnf.erb')
    set :mysql_conf_path, "/etc/mysql/my.cnf"

    set :mysql_data_dir, "/var/lib/mysql"

    def mysql_client_cmd(cmd,opts={})

      use_sudo = opts[:use_sudo] || true
      command = []
      command << "#{sudo}" if use_sudo
      command << (opts[:mysql] || "mysql")
      command << "-u#{opts[:user]}" if opts[:user]
      command << "-p" if opts[:pass]
      command << "-h#{opts[:host]}" if opts[:host]
      command << "-P#{opts[:port]}" if opts[:port]
      command << "--force" if opts[:force]
      command << "-e \"#{cmd}\"" unless cmd.nil?
      command = command.join(" ")
      utilities.run_with_input(command, /^Enter password:/, opts[:pass]) if opts[:run] != false
      command
    end

    desc "Install Mysql-server"
    task :install, :roles => :mysqld do
      #TODO: check password security, something seems off after install
      #http://serverfault.com/questions/19367/scripted-install-of-mysql-on-ubuntu
      begin
        put %w(5.0 5.1 5.5).inject("") { |memo,ver|
          memo << %Q{
            Name: mysql-server/root_password
            Template: mysql-server/root_password
            Value: #{mysql_admin_password}
            Owners: mysql-server-#{ver}
            Flags: seen

            Name: mysql-server/root_password_again
            Template: mysql-server/root_password_again
            Value: #{mysql_admin_password}
            Owners: mysql-server-#{ver}
            Flags: seen
          }
        }, "non-interactive.txt"
        sudo "DEBIAN_FRONTEND=noninteractive DEBCONF_DB_FALLBACK=Pipe apt-get -qq -y install mysql-server < non-interactive.txt"
      rescue
        raise
      ensure
        sudo "rm non-interactive.txt"
      end

    end

    task :setup, :roles => [:mysqld] do
      run "#{sudo} service mysql stop;true"
      utilities.sudo_upload_template mysql_conf, mysql_conf_path, :mode => "644", :owner => 'root:root'
      apparmor.setup
      mysql.setup_data_dir
      mysql.start
    end

    task :set_root_password, :roles => [:mysqld] do
      run "#{sudo} mysqladmin -u root password #{TeeLogWriter.redact(mysql_admin_password)}"
    end

    desc "Install Mysql Developement Libraries"
    task :install_client_libs, :except => {:no_release => true} do
      utilities.apt_install "libmysqlclient-dev"
    end

    desc "Setup the MySQL Data and Log directories"
    task :setup_data_dir, :roles => [:mysqld] do
      sudo "mkdir -p #{mysql_data_dir}"
      sudo "chown -R  mysql:mysql #{mysql_data_dir}"
      sudo "mysql_install_db --user=mysql --basedir=/usr --datadir=#{mysql_data_dir};true"
    end

    namespace :audit do
      task :default do
        user_privileges
        schema_privileges
      end

      task :user_privileges, :roles => [:db, :mysqld] do
        sudo %Q{mysql -uroot -e "SELECT * FROM information_schema.USER_PRIVILEGES;"}
      end

      task :schema_privileges, :roles => [:db, :mysqld] do
        sudo %Q{mysql -uroot -e "SELECT * FROM information_schema.SCHEMA_PRIVILEGES;"}
      end
    end

    ##
    # Steps to restore are manual
    # $ mkdir -p /mnt/mysql_restore && cd /mnt/mysql_restore
    #
    # get the url of the package you want to restore
    # ie: https://s3.amazonaws.com/prefix-mysql-backups-staging/server/2012/February/07/Wednesday/mysql_server_2012-02-15_23h02m.tar.gz/mysql_server_2012-02-15_23h02m.tar.gz.aa
    #
    # formulate the s3cmd to retrieve it
    # $ s3cmd get S3://mysql-backups-staging/server/2012/February/07/Wednesday/mysql_server_2012-02-15_23h02m.tar.gz/*
    #
    # join the parts
    # $ cat *.gz.*|tar xzf -
    #
    # cd into the dir
    # $ cd 2012-02-15_23h02m/
    #
    # execute the script supplying the database you want to restore into
    # $ ./mysql_restore.sh staging

    namespace :backup do

      desc "Transfer backup script to host"
      task :upload_backup_script, :roles => :mysqld_backup do
        run "#{sudo} mkdir -p /root/script #{mysql_backup_location} #{mysql_backup_log_path}"
        # Some backup scripts require lbzip2
        utilities.apt_install "at lbzip2"
        utilities.sudo_upload_template mysql_backup_script, mysql_backup_script_path, :mode => "700", :owner => 'root:root'
        utilities.sudo_upload_template mysql_restore_script, mysql_restore_script_path, :mode => "700", :owner => 'root:root'
      end

      desc "Trigger Backup"
      task :trigger, :roles => :mysqld_backup do
        upload_backup_script
        remove_backup_log
        sudo %Q{sh -c "echo '#{mysql_backup_script_path} > #{mysql_backup_log_path} 2>&1' | at now + 2 minutes"}
      end

      desc "validate backup"
      task :verify, :roles => :mysqld_backup do
        begin
          ensure_slave_running
          retrieve_backup_log
          check_backup_finished
        ensure
          remove_backup_log
        end
      end

      desc "checks that the backup appears to have finished"
      task :check_backup_finished, :roles => :mysqld_backup do
        run "grep 'MYSQL BACKUP FINISHED' #{mysql_backup_log_path}"
      end

      desc "retreive the backup log"
      task :retrieve_backup_log, :roles => :mysqld_backup do
        run_locally "mkdir -p #{mysql_backup_log_dest}"
        top.download mysql_backup_log_path, "#{mysql_backup_log_dest}/backup-$CAPISTRANO:HOST$.log", :via => :scp
      end

      desc "remove the backup log"
      task :remove_backup_log, :roles => :mysqld_backup do
        sudo "rm -f #{mysql_backup_log_path}"
      end

      desc "ensure slave is running"
      task :ensure_slave_running, :roles => :mysqld_backup do
        if mysql_backup_stop_sql_thread
          # It should be started, intervene if it's not.
          begin
            run %Q{test `#{mysql_client_cmd("SHOW SLAVE STATUS\G",:run => false)} | grep Running | grep -c Yes` = '2'}
          rescue => e
            raise Capistrano::Error, "Mysql threads are not running #{e.message}"
          ensure
            mysql_client_cmd("START SLAVE")
          end
        end
      end



    end


  end

end
