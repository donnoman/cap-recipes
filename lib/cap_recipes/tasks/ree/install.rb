# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')
require File.expand_path(File.dirname(__FILE__) + '/../aptitude/manage')

Capistrano::Configuration.instance(true).load do

  namespace :ree do

    set :ree_ver, 'ruby-enterprise-1.8.7-2012.02'
    set :ree_src, "http://rubyenterpriseedition.googlecode.com/files/ruby-enterprise-1.8.7-2012.02.tar.gz"

    set(:ree_pkg) {
      case target_os
      when :debian64
        "http://rubyenterpriseedition.googlecode.com/files/ruby-enterprise_1.8.7-2012.02_amd64_debian6.0.deb"
      when :ubuntu64
        "http://rubyenterpriseedition.googlecode.com/files/ruby-enterprise_1.8.7-2012.02_amd64_ubuntu10.04.deb"
      else
        raise Capistrano::Error "Unhandled target_os in :ree"
      end
    }
    set(:ree_pkg_name) { ree_pkg.match(/\/([^\/]*)$/)[1] }
    set :ree_from_source, false #if for some reason you can't use the pkg, build it from source
    set :ree_seg_fixup, false # Set to true if your logs are full of 4gb seg fixups and building from source.
    set :base_ruby_path, '/usr/local' #this interaction needs to be tested more, this could be a problem if they install from source
    set :ree_cflags, ""
    set :ree_cxxflags, ""
    set :ree_tcmalloc, true
    set :target_os, :ubuntu64

    desc "install ree"
    task :install, :except => {:no_ruby => true} do
      if ree_from_source
        install_from_source
      else
        install_from_package
      end
    end

    task :install_from_source, :except => {:no_ruby => true}  do
      utilities.apt_install %w[build-essential libssl-dev libmysqlclient15-dev libreadline5-dev wget]
      #this task doesn't deal with path issues yet
      run "cd /usr/local/src && #{sudo} wget --tries=2 -c --progress=bar:force #{ree_src} && #{sudo} tar xzf #{ree_ver}.tar.gz"
      run "cd /usr/local/src/#{ree_ver}/source/distro/google-perftools-* && #{sudo} sh -c './configure --prefix=#{base_ruby_path} --disable-dependency-tracking && make libtcmalloc_minimal.la'" if ree_tcmalloc
      # Get rid of the 4gb seg fixup errors
      # from: http://blog.pacharest.com/2009/08/a-bit-technical-nginx-passenger-4gb-seg-fixup/
      # http://groups.google.com/group/emm-ruby/browse_thread/thread/1b9beffe8fa694a7
      if ree_seg_fixup
        ree_cflags += " -mno-tls-direct-seg-refs"
        ree_cxxflags += " -mno-tls-direct-seg-refs"
      end
      cmd = ""
      cmd += "CFLAGS='#{ree_cflags}' " if ree_cflags
      cmd += "CXXFLAGS='#{ree_cxxflags}' " if ree_cxxflags
      cmd += "/usr/local/src/#{ree_ver}/installer --auto #{base_ruby_path}"
      sudo cmd
    end

    task :install_from_package, :except => {:no_ruby => true} do
      utilities.apt_install %w[wget]
      sudo "wget --tries=2 -c --directory-prefix=/usr/local/src --progress=bar:force #{ree_pkg}"
      sudo "dpkg -i /usr/local/src/#{ree_pkg_name}"
    end

  end
end
