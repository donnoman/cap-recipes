Capistrano::Configuration.instance(true).load do

  namespace :god do

    set(:god_daemon) {"#{base_ruby_path}/bin/god"}
    set(:god_config) {"/etc/god/config.god"}
    set(:god_confd) {"/etc/god/conf.d"}
    set :god_config_path, File.join(File.dirname(__FILE__),'config.god')
    set(:god_init) {"/etc/init.d/god"}
    set(:god_upstart_conf) {"/etc/init/god.conf"}
    set :god_init_path, File.join(File.dirname(__FILE__),'god.init')
    set :god_upstart_init_erb, File.join(File.dirname(__FILE__),'god.upstart.init.erb')
    set :god_upstart_erb, File.join(File.dirname(__FILE__),'god.upstart.erb')
    set :god_contacts_path, File.join(File.dirname(__FILE__),'contacts.god')
    set :god_log_path, nil # without a path assumes syslog
    set(:god_pid_path) {"/var/run/god.pid"}
    set :god_notify_list, "localhost"
    set :god_install_from, :package
    set :god_git_ref, "v0.13.1"
    set :god_git_repo, "git://github.com/mojombo/god.git"
    set :god_log_level, "info" # [debug|info|warn|error|fatal]
    set :god_open_socket, false
    set :god_use_terminate_on_kill, false
    set :god_watcher, nil
    set :god_supress_runner, false

    desc "select watcher"
    task :watcher do
      god.send("watch_with_#{god_watcher}".to_sym) unless god_watcher.nil?
    end

    desc "Use upstart as GOD's watcher"
    task :watch_with_upstart do
      #rejigger the maintenance tasks to use upstart
      %w(start stop).each do |t|
        task t.to_sym, :except => {:no_ruby => true} do
          run "#{sudo} initctl #{t} god" unless god_supress_runner
        end
      end

      task :install_check, :except => {:no_ruby => true} do
        begin
          run "ls #{god_upstart_conf}"
        rescue
          god.install
        end
      end
      task :restart, :except => {:no_ruby => true} do
        run "#{sudo} initctl stop god;#{sudo} initctl start god;" unless god_supress_runner
      end
      task :install, :except => {:no_ruby => true} do
        god.send("install_from_#{god_install_from}".to_sym)
        god.force_stop
        run "#{sudo} update-rc.d god remove -f;true"
        run "#{sudo} rm -f /etc/init.d/god"
        utilities.sudo_upload_template god_upstart_erb, god_upstart_conf, :owner => "root:root"
        utilities.sudo_upload_template god_upstart_init_erb, god_init, :owner => "root:root"
        run "#{sudo} initctl reload-configuration"
      end
      desc "force restart god"
      task :force_stop, :except => {:no_ruby => true} do
        run "#{sudo} initctl stop god;true" # in case it's thrashing
        run "#{sudo} /etc/init.d/god stop;true" #just for good measure
        # run "#{sudo} pkill -f '/bin/god ';true" #try's to catch all god processes but not be overzealous and kill similarly matching processes.
      end
      task :force_restart, :except => {:no_ruby => true} do
        run "#{sudo} initctl stop god;true" #just for good measure
        # run "#{sudo} pkill -f '/bin/god ';true" #try's to catch all god processes but not be overzealous and kill similarly matching processes.
        run "#{sudo} initctl start god"
      end
      task :terminate, :except => {:no_ruby => true } do
        # TODO see how to plumb terminate directly in the upstart this way is dangerous.
        god.cmd "terminate; true"
        sleep 10
        run "#{sudo} initctl stop god;true" #just for good measure
        sleep 10
        run "pkill -9 -f god;true"
      end
    end


    def cmd(cmd,options={})
      r_env = options[:rails_env] || rails_env
      # This protects the deploy if god is down for some reason, we have an opportunity to restart it and continue on.
      begin
        run "#{sudo unless god_open_socket} PATH=#{base_ruby_path}/bin:$PATH #{god_daemon} status" unless %w(terminate quit).any?{|c| cmd =~ c }
      rescue
        god.restart
        logger.info "sleeping 10 for god to restart"
        sleep 10
      end
      run "#{sudo unless god_open_socket} PATH=#{base_ruby_path}/bin:$PATH #{god_daemon} #{cmd}"
    end

    # Use this helper to upload god conf.d files and reload god
    # god.upload god_contacts_path, "contacts.god"
    def upload(src,name)
      sudo "mkdir -p #{god_confd}"
      utilities.sudo_upload_template src, "#{god_confd}/#{name}"
    end

    # Built this helper to remove the uploaded god conf.d files and reload god
    # god.remove god_contacts_path, "contacts.god"
    def remove(name)
      sudo "rm -rf #{god_confd}/#{name}"
    end

    # TODO: update rubies other than ruby19 to conform
    # New Concept ':except => {:no_ruby => true}' to allow all systems by default
    # to have ruby installed to allow use of ruby gems like god on all systems
    # regardless of whether they have releases deployed to them, they may have other things
    # that we want god to watch on them.

    desc "install god"
    task :install, :except => {:no_ruby => true} do
      god.send("install_from_#{god_install_from}".to_sym)
      utilities.sudo_upload_template god_init_path, god_init, :mode => "+x"
      sudo "update-rc.d -f god defaults"
    end

    desc "installs god if the init file is not present"
    task :install_check, :except => {:no_ruby => true} do
      begin
        run "ls #{god_init}"
      rescue
        god.install
      end
    end

    desc "install god init"
    task :install_from_package, :except => {:no_ruby => true} do
      utilities.gem_install "god"
    end

    task :install_from_git, :except => {:no_ruby => true} do
      utilities.gem_install "json"
      utilities.gem_uninstall "god"
      sudo "mkdir -p /usr/local/src"
      utilities.git_clone_or_pull(god_git_repo,"/usr/local/src/god",god_git_ref)
      utilities.run_compressed %Q{
        cd /usr/local/src/god;
        #{sudo} rm -f *.gem;
        #{sudo} #{base_ruby_path}/bin/gem build *.gemspec;
        #{sudo} #{base_ruby_path}/bin/gem install -y --no-rdoc --no-ri *.gem;
      }
    end

    desc "clear god conf.d directory"
    task :clear_confd, :except => {:no_ruby => true} do
      sudo "rm -rf #{god_confd}" #make sure the god_confd is clear for setup.
      sudo "mkdir -p #{god_confd}"
    end

    desc "setup god"
    task :setup, :except => {:no_ruby => true} do
      utilities.sudo_upload_template god_config_path, god_config
    end

    desc "upload god contacts"
    task :contacts, :except => {:no_ruby => true} do
      god.upload god_contacts_path, 'contacts.god'
    end

    %w(start stop restart).each do |t|
      desc "#{t} God"
      task t.to_sym, :except => {:no_ruby => true} do
        sudo "/etc/init.d/god #{t}"
      end
    end

    desc "force restart god"
    task :force_restart, :except => {:no_ruby => true} do
      god.cmd "quit;true"
      sudo "/etc/init.d/god stop;true" #just for good measure
      sudo "/etc/init.d/god start"
    end

    desc "force restart god"
    task :force_stop, :except => {:no_ruby => true} do
      sudo "service god stop; true"
      god.cmd "quit;true"
      sudo "/etc/init.d/god stop;true" #just for good measure
    end

    desc "god status"
    task :status, :except => {:no_ruby => true} do
      god.cmd "status"
    end

    desc "reload the god config"
    task :reload, :except => {:no_ruby => true} do
      god.cmd "load #{god_config};true"
    end

    desc "terminate god and everything it's watching"
    task :terminate, :except => {:no_ruby => true } do
      god.cmd "terminate; true"
      sleep 10
      sudo "/etc/init.d/god stop;true"
      sleep 10
      sudo "pkill -9 -f god;true"
    end

  end
end
