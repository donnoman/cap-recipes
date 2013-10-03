Capistrano::Configuration.instance(true).load do

  namespace :nrpe do
    roles[:nrpe]
    set :nrpe_root, "/etc/nagios"
    set(:nrpe_cfg_file) {"#{nrpe_root}/nrpe.cfg"}
    set :nrpe_cfg_erb, File.join(File.dirname(__FILE__),'nrpe.cfg.erb')

    desc "Install nrpe"
    task :install, :roles => :nrpe do
      utilities.apt_install "nagios-nrpe-server nagios-plugins-basic nagios-plugins nagios-plugins-standard nagios-plugins-extra"
    end

    desc "Install nrperc settings"
    task :setup, :roles => :nrpe do
      utilities.sudo_upload_template nrpe_cfg_erb, nrpe_cfg_file, :owner => "root:root", :mode => "0700"
    end

    %w(start stop restart).each do |t|
      desc "#{t} nrpe"
      task t.to_sym, :roles => :nrpe do
        sudo "/etc/init.d/nagios-nrpe-server #{t}"
      end
    end

  end
end
