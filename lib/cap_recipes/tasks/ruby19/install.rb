require File.expand_path(File.dirname(__FILE__) + '/../utilities')
require File.expand_path(File.dirname(__FILE__) + '/../aptitude/manage')

Capistrano::Configuration.instance(true).load do

  namespace :ruby19 do

    set :ruby_ver, 'ruby-1.9.3-p327'
    set(:ruby_src){"ftp://ftp.ruby-lang.org/pub/ruby/1.9/#{ruby_ver}.tar.bz2"}
    set :base_ruby_path, '/usr'

    # New Concept ':except => {:no_ruby => true}' to allow all systems by default
    # to have ruby installed to allow use of ruby gems like god on all systems
    # regardless of whether they have releases deployed to them, they may have other things
    # that we want god to watch on them.

    desc "install ruby"
    task :install, :except => {:no_ruby => true} do
      utilities.apt_install %w[build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool]
      sudo "mkdir -p /usr/local/src/"
      run "#{sudo} rm -rf /usr/local/src/#{ruby_ver}" #make clean is not allowing a re-install  #http://www.ruby-forum.com/topic/4409005
      run "cd /usr/local/src && #{sudo} wget --tries=2 -c --progress=bar:force #{ruby_src} && #{sudo} bunzip2 --keep --force #{ruby_ver}.tar.bz2 && #{sudo} tar xvf #{ruby_ver}.tar"
      run "cd /usr/local/src/#{ruby_ver} && #{sudo} ./configure --prefix=#{base_ruby_path} --enable-shared && #{sudo} make install"
    end

  end
end
