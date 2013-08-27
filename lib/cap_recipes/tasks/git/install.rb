require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :git do

    desc "install git"
    task :install, :except => {:no_release => true} do
      utilities.apt_install_from_ppa("ppa:git-core/ppa","git-core")
    end

    desc "git version"
    task :version, :except => {:no_release => true} do
      run "git --version"
    end

  end
end
