# @author Rick Russell <sysadmin.rick@gmail.com>
Capistrano::Configuration.instance(true).load do

  namespace :ufw do
    roles[:ufw_app]
    roles[:ufw]

    set :ufw_private_net_eths, %w(eth1)
    set :ufw_public_net_eths, %w(eth0)

    desc "install ufw"
    task :install, :roles => [:ufw,:ufw_app] do
      utilities.apt_install 'ufw'
    end

    desc "Adds ufw rules to all configured roles"
    task :setup, :roles => [:ufw,:ufw_app] do
      sudo "ufw allow ssh"
      ufw_private_net_eths.each do |eth|
        sudo "ufw allow in on #{eth}"
      end
      ufw.setup_app
      sudo "ufw default deny"
    end

    desc "setup the firewall rules for the :app role"
    task :setup_app, :roles => :ufw_app do
      sudo "ufw allow http"
      sudo "ufw allow https"
    end

    desc "ufw enable"
    task :enable, :roles => [:ufw,:ufw_app] do
      utilities.sudo_with_input("ufw enable", /Proceed with operation (y|n)?/, "y\n" )
    end

    desc "ufw status"
    task :status, :roles => [:ufw,:ufw_app] do
      sudo "ufw status verbose"
    end

  end

end
