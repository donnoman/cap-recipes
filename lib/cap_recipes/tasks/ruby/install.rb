require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :ruby do

    set :ruby_ver_latest_type, "stable" # can be major.minor numbers ie: 1.8, 2.1 etc. or 'stable'
    set(:ruby_ver_latest) { open("http://ftp.ruby-lang.org/pub/ruby/#{ruby_ver_latest_type}").read.scan(/href="(ruby-\d.\d.\d(-p\d+)?).tar.bz2/).map{|r| r[0]}.sort.reverse.first }
    set(:ruby_ver) { utilities.suggest_version(:ruby_ver,ruby_ver_latest) }

    # Ruby Versioning: ruby-MAJOR.MINOR.TEENY-pPATCHLEVEL
    set(:ruby_major_minor) { ruby_ver.match(/ruby-(\d\.\d)/)[1]}
    set(:ruby_src) { "http://cache.ruby-lang.org/pub/ruby/#{ruby_major_minor}/#{ruby_ver}.tar.bz2"}

    set :base_ruby_path, '/usr'
    set :ruby_debugger_support, false
    set :ruby_rubygems_source_fix_support, false
    set :ruby_ensure_trust_github, true

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
        utilities.gem_install("debugger-ruby_core_source -- --with-ruby-include=/usr/local/src/#{ruby_ver}")
        utilities.gem_install("debugger-linecache -- --with-ruby-include=/usr/local/src/#{ruby_ver}")
      end
    end

    desc "Remove legacy rubygems.org as gem source"
    task :rubygems_source_fix, :except => { :no_ruby => true } do
      if ruby_rubygems_source_fix_support
        run "#{sudo} gem source -a http://production.s3.rubygems.org"
        run "#{sudo} gem source -r http://rubygems.org/"
      end
    end

    task :ensure_trust_github, :except => { :no_ruby => true } do
      utilities.run_with_input("ssh -i ~/.ssh/id_rsa git@github.com;true", /\?/, "yes\n") if ruby_ensure_trust_github
    end

  end
end
