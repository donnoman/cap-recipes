# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do

  namespace :logrotate do
    set(:logrotate_path) { shared_path }
    set :logrotate_dir, 'log'
    set :logrotate_keep_logs, 10

    def log_dir(num)
      File.join(logrotate_path, num == 0 ? logrotate_dir : "#{logrotate_dir}.#{num.to_s}")
    end

    desc "rotate the log directory"
    task :rotate, :except => { :no_release => true } do
      (0..logrotate_keep_logs).to_a.reverse.each do |num|
        run "mkdir -p #{log_dir(num)}; mv #{log_dir(num)} #{log_dir(num+1)}"
      end
      run "mkdir -p #{log_dir(0)}"
      run "rm -rf #{log_dir(logrotate_keep_logs+1)}"
    end

  end
end