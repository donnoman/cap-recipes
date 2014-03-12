# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :newrelic_sysmond do
    roles[:newrelic_sysmond]
    set(:newrelic_sysmond_license_key) {utilities.ask("newrelic_sysmond_license_key:")}
    set :newrelic_sysmond_watcher, nil
    set :newrelic_sysmond_suppress_runner, false
    set :newrelic_sysmond_god_path, File.join(File.dirname(__FILE__),'newrelic_sysmond.god')
    set :newrelic_sysmond_gem_ver, "3.3.0"
    set :newrelic_sysmond_contrib_gem_ver, "2.1.6"
    set :newrelic_sysmond_hostname_cmd, "hostname -f 2>/dev/null || hostname"
    set :newrelic_sysmond_cfg_template, File.join(File.dirname(__FILE__),'nrsysmond.cfg.erb')
    set :newrelic_sysmond_cfg_file, "/etc/newrelic/nrsysmond.cfg"
    set :newrelic_sysmond_update_apt_sources, true

    desc 'Installs newrelic_sysmond'
    task :install, :roles => :newrelic_sysmond do
      if newrelic_sysmond_update_apt_sources
        # If you are using a proxy that is configured with these keys and can't add them from the host itself you can set this to false.
        run "curl -L http://download.newrelic.com/548C16BF.gpg | #{sudo} apt-key add -"
        sudo "curl -L http://download.newrelic.com/debian/newrelic.list -o /etc/apt/sources.list.d/newrelic.list"
        utilities.apt_update
      end
      utilities.apt_install 'newrelic-sysmond'
    end

    desc "Setup newrelic_sysmond"
    task :setup, :roles => :newrelic_sysmond do
      # utilities.sudo_upload_template,
      utilities.sudo_upload_template newrelic_sysmond_cfg_template, newrelic_sysmond_cfg_file
      sudo %Q{sed -i "s/###HOSTNAME###/`#{newrelic_sysmond_hostname_cmd}`/g" #{newrelic_sysmond_cfg_file}}
    end

    desc "select watcher"
    task :watcher do
      newrelic_sysmond.send("watch_with_#{newrelic_sysmond_watcher}".to_sym) unless newrelic_sysmond_watcher.nil?
    end

    desc "Use GOD as newrelic_sysmond's runner"
    task :watch_with_god do
      #rejigger the maintenance tasks to use god when god is in play
      %w(start stop restart).each do |t|
        task t.to_sym, :roles => :newrelic_sysmond do
          god.cmd "#{t} newrelic-sysmond" unless newrelic_sysmond_suppress_runner
        end
      end
      after "god:setup", "newrelic_sysmond:setup_god"
    end

    desc "setup god to watch newrelic_sysmond"
    task :setup_god, :roles => :newrelic_sysmond do
      god.upload newrelic_sysmond_god_path, 'newrelic_sysmond.god'
    end

    %w(start stop restart).each do |t|
      desc "#{t} newrelic-sysmond"
      task t.to_sym, :roles => :newrelic_sysmond do
        sudo "/etc/init.d/newrelic-sysmond #{t}"
      end
    end

  end
end
