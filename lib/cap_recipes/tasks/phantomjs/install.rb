# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :phantomjs do
    set :phantomjs_ver, "phantomjs-1.9.1-linux-x86_64"
    set(:phantomjs_src) {"https://phantomjs.googlecode.com/files/#{phantomjs_ver}.tar.bz2"}
    set :phantomjs_prefix, '/usr'

    desc 'Installs phantomjs'
    task :install, :roles => :phantomjs do
      run "cd /usr/local/src && #{sudo} wget --tries=2 -c --progress=bar:force #{phantomjs_src} && #{sudo} bunzip2 -f #{phantomjs_ver}.tar.bz2 && #{sudo} tar xvf #{phantomjs_ver}.tar"
      run "cd /usr/local/src/#{phantomjs_ver} && #{sudo} cp bin/* #{phantomjs_prefix}/bin"
    end

    desc "Return the installed phantomjs version"
    task :version, :roles => :phantomjs do
      run "phantomjs --version"
    end

  end
end
