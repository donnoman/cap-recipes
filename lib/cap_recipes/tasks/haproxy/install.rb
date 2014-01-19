require File.expand_path(File.dirname(__FILE__) + '/../utilities')
#TODO: incorporate ryslsog config like: http://kevin.vanzonneveld.net/techblog/article/haproxy_logging/
Capistrano::Configuration.instance(true).load do
  namespace :haproxy do
    roles[:haproxy]
    set :haproxy_template_path, File.join(File.dirname(__FILE__),'haproxy.cfg')
    set :haproxy_god_path, File.join(File.dirname(__FILE__),'haproxy.god')
    set(:haproxy_user) {"haproxy"}
    set(:haproxy_group) {"haproxy"}
    set :haproxy_runner, :init
    set :haproxy_suppress_runner, false
    set :haproxy_install_from, :package

    desc "Install Haproxy"
    task :install do
      if haproxy_install_from == :package
        install_from_package
      end
    end

    desc "Install Haproxy by Package"
    task :install_from_package, :roles => :haproxy do
      # http://www.zimbio.com/Ubuntu+Linux/articles/7Wwgp74q4ze/How+Install+HAProxy+Ubuntu+11+04
      utilities.apt_install "haproxy"
      # in Ubuntu the /etc/init.d/haproxy script tries to start before networking and fails.
      sudo "update-rc.d -f haproxy remove"
      sudo "update-rc.d -f networking remove"
      sudo "update-rc.d haproxy start 37 2 3 4 5 . stop 20 0 1 6 ."
      sudo "update-rc.d networking start 34 2 3 4 5 ."
    end

    desc "Enable Haproxy"
    task :enable, :roles => :haproxy do
      sudo "sed -i 's/ENABLED=.*/ENABLED=1/g' /etc/default/haproxy"
    end

    desc "Disable Haproxy"
    task :disable, :roles => :haproxy do
      sudo "sed -i 's/ENABLED=.*/ENABLED=0/g' /etc/default/haproxy"
    end

    desc "select Haproxy runner"
    task :runner do
      haproxy.send("run_with_#{haproxy_runner}".to_sym)
    end

    desc "Use INIT as haproxy's runner"
    task :run_with_init do
      %w(start stop restart).each do |t|
        task t.to_sym, :roles => :haproxy do
          sudo "/etc/init.d/haproxy #{t}" unless haproxy_suppress_runner
        end
      end
    end

    desc "Use GOD as haproxy's runner"
    task :run_with_god do
      %w(start stop restart).each do |t|
        task t.to_sym, :roles => :haproxy do
          god.cmd "#{t} haproxy" unless haproxy_suppress_runner
        end
      end
      after "god:setup", "haproxy:setup_god"
    end

    desc "setup god to watch haproxy"
    task :setup_god, :roles => :haproxy do
      god.upload haproxy_god_path, 'haproxy.god'
    end

    desc "setup haproxy"
    task :setup, :roles => :haproxy do
      utilities.sudo_upload_template haproxy_template_path, "/etc/haproxy/haproxy.cfg", :owner => "#{haproxy_user}:#{haproxy_group}"
    end

  end
end
