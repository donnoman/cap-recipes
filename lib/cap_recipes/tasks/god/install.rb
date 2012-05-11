Capistrano::Configuration.instance(true).load do

  namespace :god do

    set(:god_daemon) {"#{base_ruby_path}/bin/god"}
    set(:god_config) {"/etc/god/config.god"}
    set(:god_confd) {"/etc/god/conf.d"}
    set :god_config_path, File.join(File.dirname(__FILE__),'config.god')
    set(:god_init) {"/etc/init.d/god"}
    set :god_init_path, File.join(File.dirname(__FILE__),'god.init')
    set :god_contacts_path, File.join(File.dirname(__FILE__),'contacts.god')
    set :god_log_path, nil # without a path assumes syslog
    set(:god_pid_path) {"/var/run/god.pid"}
    set :god_notify_list, "localhost"
    set :god_install_from, :package
    set :god_git_ref, "v0.11.0"
    set :god_git_repo, "git://github.com/mojombo/god.git"
    set :god_log_level, "info" # [debug|info|warn|error|fatal]
    set :god_open_socket, false
    set :god_use_terminate_on_kill, false

    def cmd(cmd,options={})
      r_env = options[:rails_env] || rails_env
      run "#{sudo unless god_open_socket} PATH=#{base_ruby_path}/bin:$PATH #{god_daemon} #{cmd}"
    end

    # Use this helper to upload god conf.d files and reload god
    # god.upload god_contacts_path, "contacts.god"
    def upload(src,name)
      sudo "mkdir -p #{god_confd}"
      utilities.sudo_upload_template src, "#{god_confd}/#{name}"
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
      sudo "rm -rf #{god_confd}" #make sure the god_confd is clear for setup.
      sudo "mkdir -p #{god_confd}"
    end

    desc "install god init"
    task :install_from_package, :except => {:no_ruby => true} do
      utilities.gem_install "god"
    end

    task :install_from_git, :except => {:no_ruby => true} do
      utilities.gem_install "json"
      utilities.git_clone_or_pull(god_git_repo,"/usr/local/src/god",god_git_ref)
      utilities.run_compressed %Q{
        cd /usr/local/src/god;
        #{sudo} rm -f *.gem;
        #{sudo} #{base_ruby_path}/bin/gem build *.gemspec;
        #{sudo} #{base_ruby_path}/bin/gem install -y --no-rdoc --no-ri *.gem;
      }
    end

    desc "setup god"
    task :setup, :except => {:no_ruby => true} do
      utilities.sudo_upload_template god_config_path, god_config
    end

    desc "upload god contacts"
    task :contacts do
      god.upload god_contacts_path, 'contacts.god'
    end

    %w(start stop restart status).each do |t|
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
