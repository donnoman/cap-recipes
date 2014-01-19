# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :sdagent do
    roles[:sdagent]
    set :sdagent_root, "/etc/sd-agent"
    set :sdagent_bin, "/usr/bin/sd-agent"
    set(:sdagent_plugins_dir) { "#{sdagent_root}/plugins" }
    set :sdagent_suppress_runner, false
    set :sdagent_watcher, nil
    set :sdagent_god_path, File.join(File.dirname(__FILE__),'sdagent.god')

    #todo: deal with adding the unique key for the configuration
    task :install, :roles => :sdagent do
      sudo "wget http://www.serverdensity.com/downloads/boxedice-public.key"
      sudo "apt-key add boxedice-public.key; rm -f boxedice-public.key"
      put %Q{
        deb http://www.serverdensity.com/downloads/linux/deb all main
      },'/tmp/serverdensity.list'
      sudo "mv /tmp/serverdensity.list /etc/apt/sources.list.d/serverdensity.list"
      sdagent.update
      sdagent.setup
      sdagent.restart unless sdagent_watcher == :god
    end

    desc "select watcher"
    task :watcher do
      sdagent.send("watch_with_#{sdagent_watcher}".to_sym) unless sdagent_watcher.nil?
    end

    desc "Use GOD as sdagents's runner"
    task :watch_with_god do
      #rejigger the maintenance tasks to use god when god is in play
      %w(start stop restart).each do |t|
        task t.to_sym, :roles => :sdagent do
          god.cmd "#{t} sdagent" unless sdagent_suppress_runner
        end
      end
      before "god:setup", "sdagent:setup_god"
      after "sdagent:uninstall", "sdagent:unsetup_god"
    end

    desc "uninstall sd-agent from all roles"
    task :uninstall, :on_error => :continue do
      utilities.apt_remove "sd-agent"
      utilities.apt_autoremove
    end

    desc "setup god to watch sdagent"
    task :setup_god, :roles => :sdagent do
      sudo "mkdir -p /var/run/sd-agent"
      sudo "chown sd-agent:sd-agent /var/run/sd-agent"
      god.upload sdagent_god_path, 'sdagent.god'
      # disable init from automatically starting and stopping these init controlled apps
      # god will be started by init, and in turn start these god controlled apps.
      # but leave the init script in place to be called manually
      sudo "update-rc.d -f sd-agent remove; true"
      #if you simply remove lsb driven links an apt-get can later reinstall them
      #so we explicitly define the kill scripts.
      sudo "update-rc.d sd-agent stop 20 2 3 4 5 .; true"
    end

    task :unsetup_god, :roles => :sdagent do
      sudo "rm -f #{god_confd}/sdagent.god"
      god.restart
    end

    task :update, :roles => :sdagent do
      # recover from a botched sd-agent update
      begin; sudo "pkill -f apt-get"; rescue; end
      begin; sudo "pkill -f dpkg"; rescue; end
      utilities.sudo_with_input "dpkg --configure -a", /\?/, "\n"
      # end recover
      utilities.sudo_with_input "DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND=noninteractive apt-get -qyu --force-yes install sd-agent python-mysqldb python-dev", /\?/, "\n"
    end

    task :setup, :roles => :sdagent do
      sudo "mkdir -p #{sdagent_plugins_dir}"
    end

  end
end
