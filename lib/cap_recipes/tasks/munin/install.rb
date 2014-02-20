# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do
  #https://github.com/jnstq/munin-nginx-ubuntu

  # defaults:
  # dbdir /var/lib/munin
  # htmldir /var/cache/munin/www
  # logdir /var/log/munin
  # rundir  /var/run/munin

  namespace :munin do
    task :install, :roles => :munin do
      utilities.apt_install "munin"
      install_node
    end
    task :install_node do
      utilities.apt_install "munin-node"
      #munin node plugins, cpu, df, if_eth0, if_eth1, load, iostat, swap
    end
  end
end
