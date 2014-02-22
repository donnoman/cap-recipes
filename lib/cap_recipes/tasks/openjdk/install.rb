require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :openjdk do
    roles[:openjdk]
    set(:openjdk_version) {utilities.ask("What version: (6|7)", "7")}

    desc "install java"
    task :install, :roles => :openjdk do
      utilities.apt_install_from_ppa "ppa:openjdk/ppa","openjdk-#{openjdk_version}"
    end

  end
end
