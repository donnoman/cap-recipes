# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  # EC2 no longer mounts ephemeral swap stores on instance types other than m1.small and c1.medium, this can provide a file based swap storage on the ephemeral volume already mounted.

  namespace :dphys_swapfile do

    roles[:dphys_swapfile]
    set :dphys_swapfile_erb, File.join(File.dirname(__FILE__),'dphys-swapfile.erb')
    set :dphys_swapfile_location, '/mnt/swap.file'
    set :dphys_swapfile_size, "4096"

    desc 'Installs dphys_swapfile'
    task :install, :roles => :dphys_swapfile do
      utilities.sudo_upload_template dphys_swapfile_erb, "/etc/dphys-swapfile"
      utilities.apt_install "dphys-swapfile"
    end

    %w(start stop).each do |t|
      task t.to_sym, :roles => :dphys_swapfile do
        run "#{sudo} /etc/init.d/dphys-swapfile #{t}"
      end
    end

    task :restart, :roles => :dphys_swapfile do
      run "#{sudo} /etc/init.d/dphys-swapfile stop; #{sudo} /etc/init.d/dphys-swapfile start"
    end

  end

end
