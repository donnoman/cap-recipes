# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do

  namespace :resque do
    roles[:resque_web] #embed resque-web into your rails app https://gist.github.com/1060167
    roles[:resque_worker]

    set :resque_template_path, File.join(File.dirname(__FILE__),'resque.yml.template')
    set :resque_host, "127.0.0.1"
    set :resque_port, "6379"
    set :resque_ver, "1.19.0"
    set :resque_worker_god_path, File.join(File.dirname(__FILE__),'resque_worker.god')
    set(:resque_root) { current_path }
    set :resque_watcher, nil
    set :resque_suppress_runner, false
    set :resque_name, "resque"
    set(:resque_user) { user }
    set(:resque_group) { user }
    set :resque_worker_count, "2"

    desc "select watcher"
    task :watcher do
      resque.send("watch_with_#{resque_watcher}".to_sym) unless resque_watcher.nil?
    end

    desc "Use GOD as resque's runner"
    task :watch_with_god do
      namespace :workers do
        %w(start stop restart).each do |t|
          task t.to_sym, :roles => :resque_worker do
            god.cmd "#{t} #{resque_name}#{"; true" if t == 'stop'}" unless resque_suppress_runner
            unless resque_suppress_runner
              begin
                sudo "pkill -QUIT -f #{resque_name}" if t == 'stop' #Clean up orphaned resque workers.
              rescue
              end
            end
          end
        end
      end
      after "god:setup", "resque:setup_god"
    end

    desc "setup god to watch resque"
    task :setup_god do
      setup_god_worker
    end

    task :setup_god_worker, :roles => :resque_worker do
      god.upload resque_worker_god_path, 'resque_worker.god'
    end

    desc "Configure the resque Template"
    task :configure, :roles => [:app, :resque_web, :resque_worker] do
      utilities.sudo_upload_template resque_template_path, "#{current_release}/config/resque.yml"
    end

    desc "install resque"
    task :install, :roles => [:app,:resque_web,:resque_worker] do
      utilities.gem_install "resque", resque_ver
    end

    namespace :workers do
      #stub the workers namespace to avoid errors because they are in hooks.rb even if there is no watcher set.
      %w(start stop restart).each do |t|
        task t.to_sym do; end
      end
    end

  end

end
