# @author Rick Russell <sysadmin.rick@gmail.com>
require File.expand_path(File.dirname(__FILE__) + '/../graphite/install')

Capistrano::Configuration.instance(true).load do

  namespace :statsd do

    roles[:statsd]
    set :node_ref, 'v0.8.4'
    set :statsd_ref, '6cf541c9389b40'
    set :statsd_conf, File.join(File.dirname(__FILE__),'statsd.js')
    set :statsd_init, File.join(File.dirname(__FILE__),'statsd.init.sh')
    set :statsd_god_path, File.join(File.dirname(__FILE__),'statsd.god')

    desc "install Node.js and StatsD and start/restart daemons"
    task :install do
      statsd.install_packages
      statsd.install_node
      statsd.install_statsd
      statsd.setup
    end

    desc "install all necessary apt packages"
    task :install_packages, :roles => :statsd do
      utilities.apt_install %[git-core python-setuptools]
    end

    desc "Install Node.js"
    task :install_node, :roles => :statsd do
      utilities.git_clone_or_pull "git://github.com/joyent/node.git", "/opt/node/src", node_ref
      run "cd /opt/node/src && #{sudo} ./configure && #{sudo} make && #{sudo} make install"
    end

    desc "Install Etsy Statsd"
    task :install_statsd, :roles => :statsd do
      utilities.git_clone_or_pull "git://github.com/etsy/statsd.git", "/opt/statsd/src", statsd_ref
      sudo "cp -R /opt/statsd/src/ /opt/statsd/bin"
    end

    task :setup, :roles => :statsd do
      statsd.setup_statsd_conf
      statsd.setup_statsd_init
      statsd.setup_statsd_start
      # statsd.setup_god (removed because app servers call god manually, no conf.d)
    end

    desc "Setup Statsd Server config"
    task :setup_statsd_conf, :roles => :statsd do
      sudo "mkdir -p /etc/statsd"
      utilities.sudo_upload_template statsd_conf, "/etc/statsd/statsd.js", :mode => "644", :owner => 'nobody:nogroup'
    end

    desc "Setup Statsd Init"
    task :setup_statsd_init, :roles => :statsd do
      utilities.sudo_upload_template statsd_init, "/etc/init.d/statsd", :mode => "755", :owner => 'root:root'
    end

    desc "Start/Restart Services"
    task :setup_statsd_start, :roles => :statsd do
      sudo "/etc/init.d/statsd stop;true"
      sudo "/etc/init.d/statsd start"
    end

    desc "setup god to watch statsd"
    task :setup_god, :roles => :statsd do
      god.upload(statsd_god_path,"statsd.god")
    end
  end

end