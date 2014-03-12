require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :git do

    set :git_install_from, :ppa
    set :git_source_dir, "/usr/local/src"
    set :git_source_ver, "git-1.9.0"
    set(:git_source) {"https://git-core.googlecode.com/files/#{git_source_ver}.tar.gz"}

    desc "install git"
    task :install do
      send("install_from_#{git_install_from}")
    end

    task :install_from_ppa, :except => {:no_release => true} do
      utilities.apt_install_from_ppa("ppa:git-core/ppa","git-core")
    end

    task :install_from_source, :except => {:no_release => true} do
      sudo "rm -f /etc/apt/sources.list.d/git-core-ppa-precise.list"
      utilities.apt_install "build-essential libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev"
      sudo "mkdir -p #{git_source_dir}"
      run "cd #{git_source_dir}/#{git_source_ver} && #{sudo} wget --tries=2 -c --progress=bar:force #{git_source} && #{sudo} tar zxvf #{git_source_ver}.tar.gz"
      run "cd #{git_source_dir}/#{git_source_ver} && #{sudo} ./configure && #{sudo} make && #{sudo} make install"
    end

    desc "git version"
    task :version, :except => {:no_release => true} do
      run "git --version"
    end

  end
end
