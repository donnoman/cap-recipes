Capistrano::Configuration.instance(true).load do

  namespace :apparmor do
  	set :mysql_apparmor_conf, File.join(File.dirname(__FILE__),'usr.sbin.mysqld')
  	set :mysql_apparmor_path, "/etc/apparmor.d"

    desc "install apparmor on mysql servers to ensure the values are overridden"
    task :install, :roles => [:mysql_master, :mysql_slave, :mysqld] do
      utilities.apt_install 'apparmor'
    end

    desc "Setup Apparmor to allow permission to custom directories in mysql"
    task :setup, :roles => [:mysql_master, :mysql_slave, :mysqld] do
      utilities.sudo_upload_template mysql_apparmor_conf, "#{mysql_apparmor_path}/usr.sbin.mysqld", :mode => "644", :owner => "root:root"
    end

    %w(start stop restart reload).each do |t|
      desc "#{t} apparmor"
      task t.to_sym, :roles => [:mysql_master, :mysql_slave, :mysqld] do
        sudo "/etc/init.d/apparmor #{t}"
      end
    end

  end
end
