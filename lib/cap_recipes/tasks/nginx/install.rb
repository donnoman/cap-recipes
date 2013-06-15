# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

# This Nginx is targeted for the :web role meant to be acting as a front end
# to a unicorn based application

# Additions
# https://github.com/newobj/nginx-x-rid-header
# https://github.com/yaoweibin/nginx_syslog_patch

# Possible Future Additions
# https://support.newrelic.com/kb/features/tracking-front-end-time

Capistrano::Configuration.instance(true).load do

  namespace :nginx do
    roles[:nginx]
    roles[:nginx_client]

    set :nginx_init_d, "nginx"
    set :nginx_root, "/opt/nginx"
    set :nginx_conf_path, File.join(File.dirname(__FILE__),'nginx.conf')
    set :nginx_init_d_path, File.join(File.dirname(__FILE__),'nginx.init')
    set :nginx_stub_conf_path, File.join(File.dirname(__FILE__),'stub_status.conf')
    set :nginx_god_path, File.join(File.dirname(__FILE__),'nginx.god')
    set :nginx_logrotate_path, File.join(File.dirname(__FILE__),'nginx.logrotate')
    # must be above 1.1.7 http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-1180
    set :nginx_src, "http://nginx.org/download/nginx-1.2.0.tar.gz"
    set(:nginx_ver) { nginx_src.match(/\/([^\/]*)\.tar\.gz$/)[1] }
    set(:nginx_source_dir) {"#{nginx_root}/src/#{nginx_ver}"}
    set(:nginx_patch_dir) {"#{nginx_root}/src"}
    set(:nginx_log_dir) {"#{nginx_root}/logs"}
    set(:nginx_pid_file) {"#{nginx_log_dir}/nginx.pid"}
    set :nginx_watcher, nil
    set :nginx_user, "nobody"
    set :nginx_suppress_runner, false
    set :nginx_port, '80'
    set :nginx_ssl_port, '443'
    set :nginx_bind_eth, nil
    set(:nginx_bind) {"###ETH###" if nginx_bind_eth}
    set(:nginx_listen) {"#{nginx_bind}:#{nginx_port}"}
    set(:nginx_ssl_listen) {"#{nginx_bind}:#{nginx_ssl_port} ssl"}
    set :nginx_server_name, 'localhost'
    set(:nginx_server_names) {nginx_server_name}
    set :nginx_app_conf_path, File.join(File.dirname(__FILE__),'app.conf')
    set :nginx_worker_processes, "1" # should be cpu's - 1
    set(:nginx_app_conf_filename) { application }
    set(:nginx_configure_flags) {[
      "--with-debug",
      "--with-http_gzip_static_module",
      "--with-http_stub_status_module",
      "--with-http_ssl_module",
      "--add-module=#{nginx_patch_dir}/nginx_syslog_patch",
      "--add-module=#{nginx_patch_dir}/nginx-x-rid-header",
      "--with-ld-opt=-lossp-uuid",
      "--with-cc-opt=-I/usr/include/ossp"
    ]}
    set :nginx_cert_name, nil
    set :nginx_cert_path, nil
    set(:nginx_cert_location) { "#{nginx_root}/conf/keys"}
    set :uninstall_apt_nginx, false #false may cause problems with the init.d and leave orhpans, true will destroy the remnants of whatever used to be there.
    set :nginx_redirect_www_to_base_domain, true
    set :nginx_upload_certs, true
    set :nginx_max_fails, "10"
    set :nginx_fail_timeout, "15"
    set :nginx_redirects, nil

    def ipaddress(eth)
      %Q{`ifconfig #{eth} | awk '/inet addr/ {split ($2,A,":"); print A[2]}'`}
    end

    task :upload_certs, :roles => [:web,:nginx,:nginx_client] do
      if nginx_cert_name and nginx_upload_certs
        sudo "mkdir -p #{nginx_cert_location}"
        utilities.sudo_upload_template File.join(nginx_cert_path,"#{nginx_cert_name}.key"), "#{nginx_cert_location}/#{nginx_cert_name}.key"
        utilities.sudo_upload_template File.join(nginx_cert_path,"#{nginx_cert_name}.crt"), "#{nginx_cert_location}/#{nginx_cert_name}.crt"
      end
    end

    desc "select watcher"
    task :watcher do
      nginx.send("watch_with_#{nginx_watcher}".to_sym) unless nginx_watcher.nil?
    end

    desc "Use GOD as nginx's runner"
    task :watch_with_god do
      #rejigger the maintenance tasks to use god when god is in play
      %w(start stop restart).each do |t|
        task t.to_sym, :roles => :web do
          god.cmd "#{t} nginx" unless nginx_suppress_runner
        end
      end
      after "god:setup", "nginx:setup_god"
    end

    desc "setup god to watch nginx"
    task :setup_god, :roles => [:web,:nginx] do
      god.upload nginx_god_path, 'nginx.god'
    end

    desc "remove nginx installed by apt-get if present"
    task :uninstall_apt_nginx, :roles => [:web,:nginx] do
      run "#{sudo} /etc/init.d/nginx stop;true"
      utilities.apt_remove "nginx"
      run "#{sudo} rm -rf /etc/nginx"
    end

    desc 'Installs nginx for web'
    task :install, :roles => [:web,:nginx] do
      uninstall_apt_nginx if fetch(:uninstall_apt_nginx)
      utilities.apt_install "build-essential libssl-dev zlib1g-dev libcurl4-openssl-dev libpcre3-dev libossp-uuid-dev git-core"
      sudo "mkdir -p #{nginx_source_dir}"
      run "cd #{nginx_root}/src && #{sudo} wget --tries=2 -c --progress=bar:force #{nginx_src} && #{sudo} tar zxvf #{nginx_ver}.tar.gz"
      utilities.git_clone_or_pull "git://github.com/yaoweibin/nginx_syslog_patch.git", "#{nginx_patch_dir}/nginx_syslog_patch"
      utilities.git_clone_or_pull "git://github.com/newobj/nginx-x-rid-header.git", "#{nginx_patch_dir}/nginx-x-rid-header"
      run "cd #{nginx_source_dir} && #{sudo} sh -c 'patch -p1 < #{nginx_patch_dir}/nginx_syslog_patch/syslog_#{nginx_ver.split('-').last}.patch'"
      run "cd #{nginx_source_dir} && #{sudo} ./configure --prefix=#{nginx_root} #{nginx_configure_flags.join(" ")} && #{sudo} make && #{sudo} make install"
    end

    task :setup, :roles => [:web,:nginx] do
      sudo "mkdir -p #{nginx_root}/conf/sites-available #{nginx_root}/conf/sites-enabled #{nginx_log_dir}"
      utilities.sudo_upload_template nginx_conf_path,"#{nginx_root}/conf/nginx.conf", :owner => "root:root"
      utilities.sudo_upload_template nginx_stub_conf_path,"#{nginx_root}/conf/sites-available/stub_status.conf", :owner => "root:root"
      sudo "ln -sf #{nginx_root}/conf/sites-available/stub_status.conf #{nginx_root}/conf/sites-enabled/stub_status.conf"
      utilities.sudo_upload_template nginx_init_d_path,"/etc/init.d/#{nginx_init_d}", :owner => "root:root", :mode => "u+x"
      utilities.sudo_upload_template nginx_logrotate_path,"/etc/logrotate.d/#{nginx_init_d}", :owner => "root:root"
    end

    desc "Nginx Unicorn Reload"
    task :reload, :roles => [:web,:nginx,:nginx_client] do
      sudo "/etc/init.d/#{nginx_init_d} reload"
    end

    desc "Nginx Unicorn Reopen"
    task :reopen, :roles => [:web,:nginx] do
      sudo "/etc/init.d/#{nginx_init_d} reopen"
    end

    task :remove_default, :roles => [:web,:nginx] do
      sudo "rm -f #{nginx_root}/sites-enabled/default"
    end

    desc "Watch Nginx and Unicorn Workers with GOD"
    task :setup_god, :roles => [:web,:nginx] do
      god.upload nginx_god_path, "nginx.god"
      # disable init from automatically starting and stopping these init controlled apps
      # god will be started by init, and in turn start these god controlled apps.
      # but leave the init script in place to be called manually
      sudo "update-rc.d -f nginx remove; true"
      #if you simply remove lsb driven links an apt-get can later reinstall them
      #so we explicitly define the kill scripts.
      sudo "update-rc.d nginx stop 20 2 3 4 5 .; true"
    end

    desc "Setup sd-agent to collect metrics for nginx"
    task :setup_sdagent, :roles => [:web,:nginx] do
      # block executing this task if :sdagent isn't present on any :web servers.
      if (find_servers(:roles => :web).map{|d| d.host} && find_servers(:roles => :sdagent).map{|d| d.host}).any?
        sudo "sed -i 's/^.*nginx_status_url.*$/nginx_status_url: http:\\/\\/127.0.0.1\\/nginx_status/g' #{sdagent_root}/config.cfg"
      end
    end

    desc "Write the application conf"
    task :configure, :roles => [:web,:nginx_client] do
      utilities.sudo_upload_template nginx_app_conf_path, "#{nginx_root}/conf/sites-available/#{nginx_app_conf_filename}.conf", :owner => "root:root"
      sudo %Q{sed -i "s/#{nginx_bind}/#{ipaddress(nginx_bind_eth)}/g" #{nginx_root}/conf/sites-available/#{nginx_app_conf_filename}.conf} if nginx_bind_eth
      enable
    end

    desc "Enable the application conf"
    task :enable, :roles => [:web,:nginx,:nginx_client] do
      sudo "ln -sf #{nginx_root}/conf/sites-available/#{nginx_app_conf_filename}.conf #{nginx_root}/conf/sites-enabled/#{nginx_app_conf_filename}.conf"
    end

    desc "Disable the application conf"
    task :disable, :roles => [:web,:nginx,:nginx_client] do
      sudo "rm #{nginx_root}/conf/sites-enabled/#{nginx_app_conf_filename}.conf"
    end

    %w(start stop restart).each do |t|
      desc "#{t} nginx via init"
      task t.to_sym, :roles => [:web,:nginx] do
        sudo "/etc/init.d/nginx #{t}" unless nginx_suppress_runner
      end
    end

  end
end
