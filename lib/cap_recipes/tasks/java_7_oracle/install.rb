require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :java_7_oracle do
    roles[:java_7_oracle]

    desc "install java_7_oracle"
    task :install, :roles => :java_7_oracle do
      run "#{sudo} echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | #{sudo} /usr/bin/debconf-set-selections"
      utilities.apt_install_from_ppa "ppa:webupd8team/java","oracle-java7-installer"
      run "#{sudo} update-java-alternatives -s java-7-oracle"
      utilities.apt_install "oracle-java7-set-default"
    end

  end
end
