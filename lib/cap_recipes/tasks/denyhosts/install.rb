Capistrano::Configuration.instance(true).load do
  # Denyhosts has been removed in Ubuntu 14.04 in favor of fail2ban

  namespace :denyhosts do
    set :denyhosts_root, "/var/lib/denyhosts"
    set(:denyhosts_allowed_hosts_file) {"#{denyhosts_root}/allowed-hosts"}
    set :denyhosts_allowed_hosts, %w()

    desc "Install Monit"
    task :install, :except => {:no_denyhosts => true} do
      logger.info "DEPRECATED: Denyhosts has been removed in Ubuntu 14.04 in favor of fail2ban"
      utilities.apt_install "denyhosts"
    end

    desc "Install denyhost settings"
    task :setup, :except => {:no_denyhosts => true} do
      put denyhosts_allowed_hosts.join("\n")+"\n", "/tmp/denyhosts_allowed_hosts"
      run "#{sudo} mv /tmp/denyhosts_allowed_hosts #{denyhosts_allowed_hosts_file}"
    end

    desc "clear and reinstall denyhosts"
    task :reinstall, :except => {:no_denyhosts => true}  do
      sudo "service denyhosts stop;true"
      clear
      install
    end

    task :clear, :except => {:no_denyhosts => true} do
      run "#{sudo} rm -rf #{denyhosts_root}/*"
      run "#{sudo} sed -i -e 's/^[^#].*$//g' /etc/hosts.deny; #{sudo} sed -i -e '/^$/d' /etc/hosts.deny"
    end

    %w(start stop restart).each do |t|
      desc "#{t} denyhosts"
      task t.to_sym, :except => {:no_denyhosts => true} do
        sudo "/etc/init.d/denyhosts #{t}"
      end
    end

  end
end
