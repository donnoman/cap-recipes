require File.expand_path(File.dirname(__FILE__) + '/../utilities')
require File.expand_path(File.dirname(__FILE__) + '/../aptitude/manage')

Capistrano::Configuration.instance(true).load do

  namespace :ruby19 do

    set :ruby_ver, 'ruby-1.9.3-p385'
    set(:ruby_src){"ftp://ftp.ruby-lang.org/pub/ruby/1.9/#{ruby_ver}.tar.bz2"}
    set :base_ruby_path, '/usr'
    set :ruby_debugger_support, true
    set :rubygems_source_fix_support, true

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

    desc "add ruby debugger support"
    task :ruby_debugger, :except => { :no_ruby => true } do
      if ruby_debugger_support
        run "#{sudo} gem install debugger-ruby_core_source --no-rdoc --no-ri -- --with-ruby-include=/usr/local/src/#{ruby_ver}"
        run "#{sudo} gem install debugger-linecache --no-rdoc --no-ri -- --with-ruby-include=/usr/local/src/#{ruby_ver}"
      end
    end

    desc "Remove legacy rubygems.org as gem source"
    task :rubygems_source_fix, :except => { :no_ruby => true } do
      if rubygems_source_fix_support
        run "#{sudo} gem source -a http://production.s3.rubygems.org"
        run "#{sudo} gem source -r http://rubygems.org/"
      end
    end

  end
end
