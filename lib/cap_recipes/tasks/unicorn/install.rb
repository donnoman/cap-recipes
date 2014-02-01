require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do
  namespace :unicorn do

    set :unicorn_template_path, File.join(File.dirname(__FILE__),'unicorn.rb.erb')
    set :unicorn_god_path, File.join(File.dirname(__FILE__),'unicorn.god')
    set(:unicorn_user) {user}
    set(:unicorn_group) {user}
    set :unicorn_workers, 3
    set :unicorn_backlog, 128
    set :unicorn_tries, -1
    set :unicorn_timeout, 120
    set(:unicorn_root) { current_path }
    set :unicorn_socket_location, %q{File.expand_path('../../../../shared/sockets/unicorn.sock', __FILE__)} #this IS CORRECTLY a non-interpolated string, to be evaled later.
    set :unicorn_backup_socket_location, %q{File.expand_path('../../tmp/sockets/unicorn.sock', __FILE__)} #this IS CORRECTLY a non-interpolated string, to be evaled later.
    set :unicorn_relative_socket_location, 'tmp/sockets'
    set :unicorn_watcher, nil
    set :unicorn_suppress_runner, false
    set :unicorn_suppress_configure, false
    set :unicorn_init_name, "unicorn"
    set(:unicorn_god_group_name) { "unicorns" } #must not equal the unicorn_init_name, god will fail to load complaining.
    set(:unicorn_god_name) { unicorn_init_name } #name for original compatability.
    set :unicorn_use_syslogger, false
    set :unicorn_god_start_grace, 30
    set :unicorn_god_restart_grace, 30
    set :unicorn_god_stop_grace, 30
    set :unicorn_god_stop_timeout, 120
    set :unicorn_disable_rack_attack, false

    desc "select watcher"
    task :watcher do
      unicorn.send("watch_with_#{unicorn_watcher}".to_sym) unless unicorn_watcher.nil?
    end

    desc "Use GOD as unicorn's runner"
    task :watch_with_god do
      #This is a test pattern, and may not be the best way to handle diverging
      #maintenance tasks based on which watcher is used but here goes:
      #rejigger the maintenance tasks to use god when god is in play
      %w(start stop restart).each do |t|
        task t.to_sym, :roles => :app do
          god.cmd "#{t} #{unicorn_god_name}" unless unicorn_suppress_runner
        end
      end
      after "god:setup", "unicorn:setup_god"
    end

    desc "setup god to watch unicorn"
    task :setup_god, :roles => :app do
      god.upload unicorn_god_path, "#{unicorn_init_name}.god"
    end

    desc 'Installs unicorn'
    task :install, :roles => :app do
      logger.info "unicorn install doesn't do anything, make sure your Gemfile specifies a version of unicorn"
    end

    task :configure, :roles => :app do
      # if you check in your unicorn.rb you can enable supressing this configure step
      unless unicorn_suppress_configure
        utilities.upload_template unicorn_template_path, "#{latest_release}/config/unicorn.rb"
      end
    end

    desc "decrement the number of unicorn worker processes by one"
    task :ttou, :roles => :app do
      run "pkill -TTOU -f 'unicorn master'"
    end

    desc "increment the number of unicorn worker processes by one"
    task :ttin, :roles => :app do
      run "pkill -TTIN -f 'unicorn master';true"
    end

    task :workers, :roles => :app do
      run "ps aux | grep -c '[u]nicorn worker';true"
    end

    task :stop, :roles => :app do
      run "cd #{latest_release} && kill -QUIT `cat tmp/pids/unicorn.pid`;true"
    end

    task :start, :roles => :app do
      run "cd #{latest_release} && #{base_ruby_path}/bin/unicorn_rails -c config/unicorn.rb -E #{rails_env} -D"
    end

    desc "restart unicorn"
    task :restart, :roles => :app do
      run "cd #{latest_release}; [ -f tmp/pids/unicorn.pid ] && kill -USR2 `cat tmp/pids/unicorn.pid` || #{base_ruby_path}/bin/unicorn_rails -c config/unicorn.rb -E #{rails_env} -D"
    end

    task :deprovision, :roles => :app do
      unicorn.stop
      god.remove  "#{unicorn_init_name}.god"
      god.restart
    end

    desc "unicorn finalize_update hook to ensure sockets directory is symlinked without using shared_children"
    task :finalize_update, :roles => :app do
      escaped_release = latest_release.to_s.shellescape
      commands = []
      commands << "chmod -R -- g+w #{escaped_release}" if fetch(:group_writable, true)
      [unicorn_relative_socket_location].map do |dir|
        d = dir.shellescape
        if (dir.rindex('/')) then
          commands += ["rm -rf -- #{escaped_release}/#{d}",
                       "mkdir -p -- #{escaped_release}/#{dir.slice(0..(dir.rindex('/'))).shellescape}"]
        else
          commands << "rm -rf -- #{escaped_release}/#{d}"
        end
        commands << "mkdir -p -- #{shared_path}/#{dir.split('/').last.shellescape}"
        commands << "ln -s -- #{shared_path}/#{dir.split('/').last.shellescape} #{escaped_release}/#{d}"
      end

      run commands.join(' && ') if commands.any?
    end

  end
end
