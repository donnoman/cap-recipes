# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

# bprobe is Boundary's Monitoring Agent
# http://boundary.com/why-boundary/

Capistrano::Configuration.instance(true).load do

  namespace :bprobe do
    roles[:bprobe]
    set(:bprobe_install_token) {utilities.ask("bprobe_install_token:")}
    set :bprobe_watcher, nil
    set :bprobe_suppress_runner, false
    set :bprobe_god_path, File.join(File.dirname(__FILE__),'bprobe.god')

    desc 'Installs bprobe'
    task :install, :roles => :bprobe do
      run "curl -3 -s https://app.boundary.com/assets/downloads/setup_meter.sh > setup_meter.sh"
      run "chmod +x setup_meter.sh"
      sudo "./setup_meter.sh -d -i #{bprobe_install_token}"
      run "rm -f setup_meter.sh"
    end

    desc "select watcher"
    task :watcher do
      bprobe.send("watch_with_#{bprobe_watcher}".to_sym) unless bprobe_watcher.nil?
    end

    desc "Use GOD as bprobe's runner"
    task :watch_with_god do
      #rejigger the maintenance tasks to use god when god is in play
      %w(start stop restart).each do |t|
        task t.to_sym, :roles => :bprobe do
          god.cmd "#{t} bprobe" unless bprobe_suppress_runner
        end
      end
      after "god:setup", "bprobe:setup_god"
    end

    desc "setup god to watch bprobe"
    task :setup_god, :roles => :bprobe do
      god.upload bprobe_god_path, 'bprobe.god'
    end

    %w(start stop restart).each do |t|
      desc "#{t} bprobe"
      task t.to_sym, :roles => :bprobe do
        sudo "/etc/init.d/bprobe #{t}"
      end
    end

  end
end
