Capistrano::Configuration.instance(true).load do

  namespace :denyhosts do
    set :denyhosts_root, "/var/lib/denyhosts"
    set(:denyhosts_allowed_hosts_file) {"#{denyhosts_root}/allowed-hosts"}
    set :denyhosts_allowed_hosts, %w()

    desc "Install Monit"
    task :install, :except => {:no_denyhosts => true} do
      utilities.apt_install "denyhosts"
    end

    desc "Install denyhost settings"
    task :setup, :except => {:no_denyhosts => true} do
      put denyhosts_allowed_hosts.join("\n")+"\n", "/tmp/denyhosts_allowed_hosts"
      run "#{sudo} mv /tmp/denyhosts_allowed_hosts #{denyhosts_allowed_hosts_file}"
    end

    %w(start stop restart).each do |t|
      desc "#{t} denyhosts"
      task t.to_sym, :except => {:no_denyhosts => true} do
        sudo "/etc/init.d/denyhosts #{t}"
      end
    end

  end
end
