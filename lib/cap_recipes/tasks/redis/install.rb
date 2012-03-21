Capistrano::Configuration.instance(true).load do
  #redis primer http://jramirez.tumblr.com/post/2589232577/prime-time-redis-101-set-up
  #redis primer http://library.linode.com/databases/redis/ubuntu-10.04-lucid

  namespace :redis do
    roles[:redis] #make an empty role
    roles[:redis_slave]
    roles[:redis_backup]
    set :redis_ver, 'redis-2.4.8'
    set(:redis_src) {"http://redis.googlecode.com/files/#{redis_ver}.tar.gz"}
    set :redis_base_path, "/opt/redis"

    set :redis_default_name, 'redis'
    set :redis_default_bind_eth, nil
    set :redis_default_bind, nil
    set :redis_default_port, 6379
    set :redis_default_timeout, '300'
    set :redis_default_conf_path, File.join(File.dirname(__FILE__),'redis.conf')
    set :redis_default_slave_conf_path, File.join(File.dirname(__FILE__),'redis-slave.conf')
    set :redis_default_backup, false
    set :redis_default_rdb_file, '/var/lib/redis/dump.rdb'
    set :redis_god_path, File.join(File.dirname(__FILE__),'redis.god')
    set :redis_watcher, nil
    set :redis_suppress_runner, false
    set :redis_backup_source_spec, "/var/lib/redis/dump-*.rdb"
    set :redis_backup_archive_watermark, "0m"
    set :redis_backup_s3_bucket, "redis-backups"
    set :redis_backup_log_path, "/tmp/redis_backup.log"
    set(:redis_backup_log_dest) {File.join(utilities.caproot,'log','backups')}
    set :redis_backup_script, File.join(File.dirname(__FILE__),'redis_backup_s3.sh')
    set :redis_backup_script_path, "/root/script/redis_backup_s3.sh"
    set :redis_backup_location, "/mnt/redis_backups"
    set :redis_backup_chunk_size, "250M"

    set :redis_master_host, nil
    set :redis_masterauth, nil
    set :redis_slave_serve_stale_data, true

    set :redis_slave_master_host, nil
    set :redis_slave_masterauth, nil
    set :redis_slave_slave_serve_stale_data, true


    set(:redis_layout) {
      [{:path => redis_base_path }] #if there's only the default then use the root of the path.
    }

    set :redis_init_path, File.join(File.dirname(__FILE__),'redis.init')
    set :redis_logrotate_path, File.join(File.dirname(__FILE__),'redis.logrotate')
    set :redis_cli_helper_path, File.join(File.dirname(__FILE__),'redis-cli-config.sh')
    #  set(:redis_cli_cmd) {"#{redis_path}/bin/redis-cli#{" -h #{redis_bind}" if redis_bind}#{" -p #{redis_port}" if redis_port} "}


    def ipaddress(eth)
      %Q{`ifconfig #{eth} | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`}
    end

    desc "install redis-server"
    task :install, :roles => [:redis,:redis_slave] do
      utilities.apt_install %w[build-essential wget]
      utilities.addgroup "redis", :system => true
      utilities.adduser "redis" , :nohome => true, :group => "redis", :system => true, :disabled_login => true
      sudo "mkdir -p #{redis_base_path}/bin #{redis_base_path}/src /var/run/redis /var/log/redis"
      run "cd #{redis_base_path}/src && #{sudo} wget --tries=2 -c --progress=bar:force #{redis_src} && #{sudo} tar xzf #{redis_ver}.tar.gz"
      run "cd #{redis_base_path}/src/#{redis_ver} && #{sudo} make"
      #sudo "/etc/init.d/#{redis_name} stop;true" #If this is a re-install need to stop redis
      run "cd #{redis_base_path}/src/#{redis_ver} && #{sudo} make PREFIX=#{redis_base_path} install"
      sudo "cp #{redis_base_path}/src/#{redis_ver}/redis.conf #{redis_base_path}/redis.conf.original"
      sudo "chown -R redis:redis #{redis_base_path} /var/run/redis /var/log/redis"
    end

    # desc "push a redis cli helper to read a config and launch the right cli"
    # task :cli_helper, :roles => :redis do
    #   utilities.sudo_upload_template redis_cli_helper_path, File.join(redis_base_path,"bin","redis-cli-config"), :mode => "+x", :owner => 'root:root'
    # end

    desc "select redis watcher"
    task :watcher do
      redis.send("watch_with_#{redis_watcher}".to_sym) unless redis_watcher.nil?
    end

    desc "Use GOD as redis's runner"
    task :watch_with_god do
      #This is a test pattern, and may not be the best way to handle diverging
      #maintenance tasks based on which watcher is used but here goes:
      #rejigger the maintenance tasks to use god when god is in play
      %w(start stop restart).each do |t|
        task t.to_sym, :roles => :redis do
          god.cmd "#{t} redi" unless redis_suppress_runner
        end
      end
      after "god:setup", "redis:setup_god"
    end

    desc "setup god to watch redis"
    task :setup_god, :roles => [:redis,:redis_slave] do
      with_layout do
        god.upload redis_god_path, "#{redis_name}.god"
      end
    end

    desc "push a redis logrotate config"
    task :logrotate, :roles => [:redis,:redis_slave] do
      utilities.sudo_upload_template redis_logrotate_path, "/etc/logrotate.d/redis", :owner => 'root:root'
    end

    desc "setup redis-server"
    task :setup, :roles => [:redis,:redis_slave] do
      with_layout do
        sudo "touch /var/log/#{redis_name}.log"
        sudo "mkdir -p #{redis_path}"
        sudo "chown redis:redis /var/log/#{redis_name}.log"
        sudo "chown -R redis:redis #{redis_path}"
        utilities.sudo_upload_template redis_init_path, "/etc/init.d/#{redis_name}", :mode => "+x", :owner => 'root:root'
      end

      redis.setup_master
      redis.setup_slave

      with_layout do
        sudo "sed -i s/#{redis_bind}/#{ipaddress(redis_bind_eth)}/g #{redis_path}/#{redis_name}.conf"
        sudo "update-rc.d -f #{redis_name} defaults"
      end

    end

    desc "setup redis-server master"
    task :setup_master, :roles => :redis do
      with_layout do
        utilities.sudo_upload_template redis_conf_path, "#{redis_path}/#{redis_name}.conf", :owner => "redis:redis"
      end
    end

    desc "setup redis-server slaves"
    task :setup_slave, :roles => :redis_slave do
      with_layout do
        utilities.sudo_upload_template redis_slave_conf_path, "#{redis_path}/#{redis_name}.conf", :owner => "redis:redis"
      end
    end

    desc "verify the redis-server"
    task :verify, :roles => [:redis,:redis_slave] do
      run "#{redis_base_path}/bin/redis-server -v"
    end

    %w(start stop restart).each do |t|
      desc "#{t.capitalize} redis server"
      task t.to_sym, :roles => [:redis,:redis_slave] do
        utilities.ask("Starting all of the redi at the same time could create a thundering herd, ctrl-c to abort.") unless t == 'stop'
        with_layout do
          #Process won't start unless protected by nohup
          sudo "nohup /etc/init.d/#{redis_name} #{t} > /dev/null"
        end
      end
    end

    ##
    # Steps to restore are manual
    # $ mkdir -p /mnt/redis_restore && cd /mnt/redis_restore
    #
    # get the url of the package you want to restore
    # ie: https://s3.amazonaws.com/redis-backups-staging/server/2012/February/07/Thursday/redis_server_2012-02-16_00h49m.tar.gz/redis_nori_2012-02-16_00h49m.tar.gz.aa
    #
    # formulate the s3cmd to retrieve it
    # $ s3cmd get S3://redis-backups-staging/server/2012/February/07/Thursday/redis_server_2012-02-16_00h49m.tar.gz/*
    #
    # join the parts
    # $ cat *.gz.*|tar xzf -
    #
    # cd into the dir
    # $ cd 2012-02-16_00h49m/
    #
    # stop redis
    # mv *.rdb and *.aof to a backup location #if the aof is present it will be read instead of the .rdb
    # cp the restored contents to the data directory of the redis being restored.
    # start redis
    # check a redis info command against the info.log

    namespace :backup do

      desc "Transfer backup script to host"
      task :upload_backup_script, :roles => :redis_backup do
        run "#{sudo} mkdir -p /root/script"
        run "#{sudo} mkdir -p #{redis_backup_location}"
        utilities.apt_install "at"
        utilities.sudo_upload_template redis_backup_script, redis_backup_script_path, :mode => "654", :owner => 'root:root'
        with_layout do
          sudo "sed -i s/#{redis_bind}/#{ipaddress(redis_bind_eth)}/g #{redis_backup_script_path}"
        end
      end

      desc "Trigger Backup"
      task :trigger, :roles => :redis_backup do
        upload_backup_script
        remove_backup_log
        sudo %Q{bash -c "echo '/root/script/redis_backup_s3.sh > #{redis_backup_log_path} 2>&1' | at now"}
      end

      desc "validate backup"
      task :verify, :roles => :redis_backup do
        begin
          retrieve_backup_log
          check_backup_finished
        ensure
          remove_backup_log
        end
      end

      desc "checks that the backup appears to have finished"
      task :check_backup_finished, :roles => :redis_backup do
        run "grep 'REDIS BACKUP FINISHED' #{redis_backup_log_path}"
      end

      desc "retreive the backup log"
      task :retrieve_backup_log, :roles => :redis_backup do
        run_locally "mkdir -p #{redis_backup_log_dest}"
        top.download redis_backup_log_path, "#{redis_backup_log_dest}/backup-$CAPISTRANO:HOST$.log", :via => :scp
      end

      desc "remove the backup log"
      task :remove_backup_log, :roles => :redis_backup do
        sudo "rm -f #{redis_backup_log_path}"
      end

    end

    ##
    # Allow a flexible configuration with multiple redis servers on the same system
    #
    # set(:redis_layout) {
    #   [
    #     {
    #       :name => 'redis',
    #       :port => '6400',
    #       :backup => true
    #     },
    #     {
    #       :name => 'redis_resque',
    #       :port => '6600',
    #       :backup => true
    #     },
    #     {
    #       :name => 'redis_cache',
    #       :port => '6700'
    #     },
    #     {
    #       :name => 'redis_vanity',
    #       :port => '6800'
    #     }
    #   ]
    # }

    def with_layout
      redis_layout.each do |layout|
        set :redis_name,      layout[:name]         || redis_default_name
        set :redis_path,      layout[:path]         || "#{redis_base_path}/#{redis_name}"
        set :redis_bind,      layout[:bind]         || redis_default_bind
        set :redis_port,      layout[:port]         || redis_default_port
        set :redis_timeout,   layout[:timeout]      || redis_default_timeout
        set :redis_conf_path, layout[:conf_path]    || redis_default_conf_path
        set :redis_slave_conf_path, layout[:slave_conf_path] || redis_default_slave_conf_path
        set :redis_bind_eth,  layout[:bind_eth]     || redis_default_bind_eth
        set :redis_backup,    layout[:backup]       || redis_default_backup
        set :redis_rdb_file,  layout[:rdb_file]     || redis_default_rdb_file
        set :redis_bind, "###ETH###" if redis_bind_eth
        yield layout if block_given?
      end
    end

  end
end
