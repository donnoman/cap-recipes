require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :gitosis do
    desc "install Gitosis"
    task :install do
      gitosis.install_packages
      gitosis.setup_packages
      gitosis.setup_git_user
      gitosis.copy_ssh
      gitosis.set_permissions
    end

    desc "install all necessary packages"
    task :install_packages do
      utilities.apt_install %[git-core python-setuptools]
    end

    desc "setup packages"
    task :setup_packages do
      run "mkdir -p ~/src"
      run "cd ~/src; git clone git://eagain.net/gitosis.git"
      run "cd ~/src/gitosis; #{sudo} python setup.py install"
    end

    desc "setup git user"
    task :setup_git_user do
      sudo "adduser --system --shell /bin/sh --gecos \'git version control\' --group --disabled-password --home /home/git git"
    end

    desc "generate ssh key"
    task :generate_ssh do
      run "rm -f /home/#{user}/.ssh/id_rsa; rm -f /home/#{user}/.ssh/id_rsa.pub"
      run "ssh-keygen -q -f /home/#{user}/.ssh/id_rsa -N \"\""
    end

    desc "copy over servers own ssh, important for self pull"
    task :copy_ssh do
      run "sudo -H -u git gitosis-init < /home/#{user}/.ssh/id_rsa.pub"
    end

    desc "set permissions"
    task :set_permissions do
      sudo "chmod 755 /home/git/repositories/gitosis-admin.git/hooks/post-update"
    end

    desc "cleanup the files"
    task :cleanup do
      sudo "rm -rf src"
    end

  end
end
