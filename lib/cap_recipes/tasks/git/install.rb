require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :git do

    desc "install git"
    task :install, :except => {:no_release => true} do
      utilities.apt_install "python-software-properties"
      run "#{sudo} add-apt-repository -y ppa:git-core/ppa"
      utilities.apt_update
      utilities.apt_install "git-core"
    end

    desc "git version"
    task :version, :except => {:no_release => true} do
      run "git --version"
    end

  end
end
