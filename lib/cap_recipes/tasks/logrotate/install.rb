# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do

  namespace :logrotate do
    set(:logrotate_path) { shared_path }
    set :logrotate_dir, 'log'
    set :logrotate_keep_logs, 10
    set :logrotate_symlink_to_path, nil # like ephemeral volumes /mnt/logs/#{application}

    def log_dir(num)
      File.join(logrotate_path, num == 0 ? logrotate_dir : "#{logrotate_dir}.#{num.to_s}")
    end

    def symlink_dir(num)
      File.join(logrotate_symlink_to_path, num == 0 ? logrotate_dir : "#{logrotate_dir}.#{num.to_s}")
    end

    def make_log_dir(num)
      if logrotate_symlink_to_path
        # TODO if log_dir not a symlink move it before doing anything
        run "mkdir -p #{symlink_dir(num)}"
        run "ln -sf #{symlink_dir(num)} #{log_dir(num)}"
        run "mv #{symlink_dir(num)} #{symlink_dir(num+1)}" unless num == 0
      else
        run "mkdir -p #{log_dir(num)}"
        run "mv #{log_dir(num)} #{log_dir(num+1)}" unless num == 0
      end
    end

    def del_log_dir(num)
      if logrotate_symlink_to_path
        run "rm #{log_dir(num)}"
        run "rm -rf #{symlink_dir(num)}"
      else 
        run "rm -rf #{log_dir(num)}"
      end
    end

    desc "rotate the log directory"
    task :rotate, :except => { :no_release => true } do
      run "mkdir -p #{logrotate_path}"
      if logrotate_symlink_to_path
        run "#{sudo} mkdir -p #{logrotate_symlink_to_path}; chown -R #{user}:#{user} #{logrotate_symlink_to_path}"
      end
      (0..logrotate_keep_logs).to_a.reverse.each do |num|
        make_log_dir(num)
      end
      make_log_dir(0)
      del_log_dir(logrotate_keep_logs+1)
    end

  end
end