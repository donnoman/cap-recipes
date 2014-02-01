# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

# This Nginx is targeted for the :app role meant to be acting as a front end
# to a unicorn based application

# Additions
# https://github.com/newobj/nginx-x-rid-header
# https://github.com/yaoweibin/nginx_syslog_patch

# Possible Future Additions
# https://support.newrelic.com/kb/features/tracking-front-end-time

Capistrano::Configuration.instance(true).load do

  namespace :nginx_unicorn do
    set :nginx_unicorn_init_d, "nginx_unicorn"
    set :nginx_unicorn_root, "/opt/nginx_unicorn"
    set :nginx_unicorn_conf_path, File.join(File.dirname(__FILE__),'nginx.conf')
    set(:nginx_unicorn_conf_dir) {"#{nginx_unicorn_root}/conf"}
    set :nginx_unicorn_init_d_path, File.join(File.dirname(__FILE__),'nginx_unicorn.init')
    set :nginx_unicorn_stub_conf_path, File.join(File.dirname(__FILE__),'stub_status.conf')
    set :nginx_unicorn_god_path, File.join(File.dirname(__FILE__),'nginx_unicorn.god')
    set :nginx_unicorn_logrotate_path, File.join(File.dirname(__FILE__),'nginx_unicorn.logrotate')
    set :nginx_unicorn_mime_types_erb, File.join(File.dirname(__FILE__),'mime.types.erb')
    # must be above 1.1.7 http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-1180
    set :nginx_unicorn_src, "http://nginx.org/download/nginx-1.2.0.tar.gz"
    set(:nginx_unicorn_ver) { nginx_unicorn_src.match(/\/([^\/]*)\.tar\.gz$/)[1] }
    set(:nginx_unicorn_source_dir) {"#{nginx_unicorn_root}/src/#{nginx_unicorn_ver}"}
    set(:nginx_unicorn_patch_dir) {"#{nginx_unicorn_root}/src"}
    set(:nginx_unicorn_upstream_socket){"#{shared_path}/sockets/unicorn.sock"}
    set(:nginx_unicorn_log_dir) {"#{nginx_unicorn_root}/logs"}
    set(:nginx_unicorn_pid_file) {"#{nginx_unicorn_log_dir}/nginx.pid"}
    set(:nginx_unicorn_sbin_file) {"#{nginx_unicorn_root}/sbin/nginx"}
    set :nginx_unicorn_watcher, nil
    set :nginx_unicorn_user, "nobody"
    set :nginx_unicorn_suppress_runner, false
    set :nginx_unicorn_port, '80'
    set :nginx_unicorn_server_name, 'localhost'
    set :nginx_unicorn_app_conf_path, File.join(File.dirname(__FILE__),'app.conf')
    set :nginx_unicorn_set_scheme, true
    set :nginx_unicorn_worker_processes, "1" # should be cpu's - 1
    set :nginx_unicorn_gzip, true
    set :nginx_unicorn_fail_timeout, nil
    set :nginx_unicorn_syslog_patch, true
    set :nginx_unicorn_rid_header_patch, false # while we want this to be true by default it makes the configurations incompatible
                                               # with the previous default. Which can cause a working NGINX to stop working until recompiled.
    set :nginx_unicorn_use_503_instead_of_502, false # useful if you are behind a load balancer that only understands 503's.

    set(:nginx_unicorn_configure_flags) {[
      "--prefix=#{nginx_unicorn_root}",
      "--sbin-path=#{nginx_unicorn_sbin_file}",
      "--pid-path=#{nginx_unicorn_pid_file}",
      "--conf-path=#{nginx_unicorn_conf_dir}/nginx.conf",
      "--with-debug",
      "--with-http_gzip_static_module",
      "--with-http_stub_status_module",
      "--with-http_ssl_module",
      "--with-ld-opt=-lossp-uuid",
      "--with-cc-opt=-I/usr/include/ossp"
    ]}

    desc "select watcher"
    task :watcher do
      nginx_unicorn.send("watch_with_#{nginx_unicorn_watcher}".to_sym) unless nginx_unicorn_watcher.nil?
    end

    desc "Use GOD as nginx_unicorn's runner"
    task :watch_with_god do
      #rejigger the maintenance tasks to use god when god is in play
      %w(start stop restart).each do |t|
        task t.to_sym, :roles => :app do
          god.cmd "#{t} nginx_unicorn" unless nginx_unicorn_suppress_runner
        end
      end
      after "god:setup", "nginx_unicorn:setup_god"
    end

    desc "setup god to watch nginx_unicorn"
    task :setup_god, :roles => :app do
      god.upload nginx_unicorn_god_path, 'nginx_unicorn.god'
    end

    desc 'Installs nginx for unicorn'
    task :install, :roles => :app do
      utilities.apt_install "libssl-dev zlib1g-dev libcurl4-openssl-dev libpcre3-dev libossp-uuid-dev git-core"
      sudo "mkdir -p #{nginx_unicorn_source_dir}"
      run "cd #{nginx_unicorn_root}/src && #{sudo} wget --tries=2 -c --progress=bar:force #{nginx_unicorn_src} && #{sudo} tar zxvf #{nginx_unicorn_ver}.tar.gz"
      if nginx_unicorn_syslog_patch
        nginx_unicorn_configure_flags << "--add-module=#{nginx_unicorn_patch_dir}/nginx_syslog_patch"
        utilities.git_clone_or_pull "git://github.com/yaoweibin/nginx_syslog_patch.git", "#{nginx_unicorn_patch_dir}/nginx_syslog_patch"
        run "cd #{nginx_unicorn_source_dir} && #{sudo} sh -c 'patch -p1 < #{nginx_unicorn_patch_dir}/nginx_syslog_patch/syslog_#{nginx_unicorn_ver.split('-').last}.patch'"
      end
      if nginx_unicorn_rid_header_patch
        nginx_unicorn_configure_flags << "--add-module=#{nginx_unicorn_patch_dir}/nginx-x-rid-header"
        utilities.git_clone_or_pull "git://github.com/newobj/nginx-x-rid-header.git", "#{nginx_unicorn_patch_dir}/nginx-x-rid-header"
      end
      run "cd #{nginx_unicorn_source_dir} && #{sudo} ./configure #{nginx_unicorn_configure_flags.join(" ")} && #{sudo} make"
      run "cd #{nginx_unicorn_source_dir} && #{sudo} make install"
    end

    task :setup, :roles => :app do
      sudo "mkdir -p #{nginx_unicorn_conf_dir}/sites-available #{nginx_unicorn_conf_dir}/sites-enabled #{nginx_unicorn_log_dir}"
      utilities.sudo_upload_template nginx_unicorn_conf_path,"#{nginx_unicorn_conf_dir}/nginx.conf"
      utilities.sudo_upload_template nginx_unicorn_mime_types_erb,"#{nginx_unicorn_conf_dir}/mime.types"
      utilities.sudo_upload_template nginx_unicorn_stub_conf_path,"#{nginx_unicorn_conf_dir}/sites-available/stub_status.conf"
      sudo "ln -sf #{nginx_unicorn_conf_dir}/sites-available/stub_status.conf #{nginx_unicorn_conf_dir}/sites-enabled/stub_status.conf"
      utilities.sudo_upload_template nginx_unicorn_init_d_path,"/etc/init.d/#{nginx_unicorn_init_d}", :mode => "u+x"
      utilities.sudo_upload_template nginx_unicorn_logrotate_path,"/etc/logrotate.d/#{nginx_unicorn_init_d}"
    end

    desc "Nginx Unicorn Reload"
    task :reload, :roles => :app do
      sudo "/etc/init.d/#{nginx_unicorn_init_d} reload"
    end

    desc "Nginx Unicorn Reopen"
    task :reopen, :roles => :app do
      sudo "/etc/init.d/#{nginx_unicorn_init_d} reopen"
    end

    task :remove_default, :roles => :app do
      sudo "rm -f #{nginx_unicorn_conf_dir}/sites-enabled/default"
    end

    desc "Watch Nginx and Unicorn Workers with GOD"
    task :setup_god, :roles => :app do
      god.upload nginx_unicorn_god_path, "#{nginx_unicorn_init_d}.god"
      # disable init from automatically starting and stopping these init controlled apps
      # god will be started by init, and in turn start these god controlled apps.
      # but leave the init script in place to be called manually
      sudo "update-rc.d -f nginx_unicorn remove; true"
      #if you simply remove lsb driven links an apt-get can later reinstall them
      #so we explicitly define the kill scripts.
      sudo "update-rc.d nginx_unicorn stop 20 2 3 4 5 .; true"
    end

    desc "Setup sd-agent to collect metrics for nginx"
    task :setup_sdagent, :roles => :app do
      # block executing this task if :sdagent isn't present on any :app servers.
      if (find_servers(:roles => :app).map{|d| d.host} & find_servers(:roles => :sdagent).map{|d| d.host}).any?
        sudo "sed -i 's/^.*nginx_status_url.*$/nginx_status_url: http:\\/\\/127.0.0.1\\/nginx_status/g' #{sdagent_root}/config.cfg"
      end
    end

    desc "Write the application conf"
    task :configure, :roles => :app do
      utilities.sudo_upload_template nginx_unicorn_app_conf_path, "#{nginx_unicorn_conf_dir}/sites-available/#{application}.conf"
      enable
    end

    desc "remove the application conf"
    task :deconfigure, :roles => :app do
      disable
      sudo "rm -rf #{nginx_unicorn_conf_dir}/sites-available/#{application}.conf"
    end

    desc "Enable the application conf"
    task :enable, :roles => :app do
      sudo "ln -sf #{nginx_unicorn_conf_dir}/sites-available/#{application}.conf #{nginx_unicorn_conf_dir}/sites-enabled/#{application}.conf"
    end

    desc "Disable the application conf"
    task :disable, :roles => :app do
      sudo "rm -f #{nginx_unicorn_conf_dir}/sites-enabled/#{application}.conf"
    end

    %w(start stop restart).each do |t|
      desc "#{t} nginx_unicorn via init"
      task t.to_sym, :roles => :app do
        sudo "/etc/init.d/#{nginx_unicorn_init_d} #{t}" unless nginx_unicorn_suppress_runner
      end
    end

  end
end
