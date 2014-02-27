require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do
  # https://launchpad.net/~webupd8team/+archive/java
  # http://www.webupd8.org/2012/01/install-oracle-java-jdk-7-in-ubuntu-via.html
  # http://www.webupd8.org/2012/06/how-to-install-oracle-java-7-in-debian.html
  # http://savvyadmin.com/download-pgp-keys-with-apt-key/
  namespace :java_7_oracle do
    roles[:java_7_oracle]
    set :java_7_oracle_ppa, "webupd8team"
    set :java_7_oracle_ppa_key, "EEA14886"
    set(:java_7_oracle_ubuntu_codename) { utilities.capture(". /etc/lsb-release; echo $DISTRIB_CODENAME").chomp}
    set(:java_7_oracle_sources_file) {"#{java_7_oracle_ppa}-java-#{java_7_oracle_ubuntu_codename}.list"}
    set :java_7_oracle_keyserver_port, "80" #11371 is the default but may be blocked by some firewalls.

    desc "install java_7_oracle"
    task :install, :roles => :java_7_oracle do
      # this pattern avoids using add-apt-repository which is currently incapable of being configured to use port 80
      run "echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | #{sudo} /usr/bin/debconf-set-selections"
      run %Q{echo "deb http://ppa.launchpad.net/#{java_7_oracle_ppa}/java/ubuntu #{java_7_oracle_ubuntu_codename} main" > /tmp/#{java_7_oracle_sources_file}}
      run %Q{echo "deb-src http://ppa.launchpad.net/#{java_7_oracle_ppa}/java/ubuntu #{java_7_oracle_ubuntu_codename} main" >> /tmp/#{java_7_oracle_sources_file}}
      run "#{sudo} mv /tmp/#{java_7_oracle_sources_file} /etc/apt/sources.list.d/#{java_7_oracle_sources_file}"
      run "#{sudo} apt-key adv --keyserver hkp://keyserver.ubuntu.com:#{java_7_oracle_keyserver_port} --recv-keys #{java_7_oracle_ppa_key}"
      utilities.apt_install "oracle-java7-installer"
      run "#{sudo} update-java-alternatives -s java-7-oracle"
      utilities.apt_install "oracle-java7-set-default"
    end

  end
end
