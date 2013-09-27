Capistrano::Configuration.instance(true).load do

  namespace :dovecot do
    roles[:dovecot]
    set :dovecot_root, "/etc/dovecot"
    set :dovecot_conf_erb, File.join(File.dirname(__FILE__),'dovecot.conf.erb')
    set :dovecot_logrotate_erb, File.join(File.dirname(__FILE__),'dovecot.conf.erb')
    set :dovecot_listen, "localhost"
    set :dovecot_ssl_cert_file, "/etc/ssl/certs/dovecot.pem"
    set :dovecot_ssl_key_file, "/etc/ssl/private/dovecot.pem"
    set :dovecot_ssl_cert_path, nil
    set :dovecot_ssl_key_path, nil

    desc "Install dovecot"
    task :install, :roles => :dovecot do
      utilities.apt_install "dovecot-pop3d"
    end

    desc "uninstall dovecot"
    task :uninstall do
      utilities.apt_purge "dovecot-pop3d"
      sudo "rm -rf /etc/logrotate.d/dovecot"
      sudo "rm -rf #{dovecot_ssl_cert_file}" if dovecot_ssl_cert_path
      sudo "rm -rf #{dovecot_ssl_key_file}" if dovecot_ssl_key_path
    end

    desc "setup dovecot"
    task :setup, :roles => :dovecot do
      utilities.sudo_upload_template dovecot_conf_erb, "#{dovecot_root}/dovecot.conf"
      utilities.sudo_upload_template dovecot_logrotate_erb, "/etc/logrotate.d/dovecot"
      utilities.sudo_upload_template dovecot_ssl_cert_path, dovecot_ssl_cert_file if dovecot_ssl_cert_path
      utilities.sudo_upload_template dovecot_ssl_key_path, dovecot_ssl_key_file if dovecot_ssl_key_path
    end

    %w(start stop restart reload).each do |t|
      desc "#{t} dovecot"
      task t.to_sym, :roles => :dovecot do
        sudo "/etc/init.d/dovecot #{t}"
      end
    end

  end
end
