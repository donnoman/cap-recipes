# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

# Provisioning hooks into many of the scripts to give a single hook to install
# the requisite software.
#
# The provisioning process assumes capistrano has been overriden to support empty roles
#
# Supported tasks add a ' after "deploy:provision", "app:install" ' in their hooks.rb
# if you don't include ' require 'cap_recipes/tasks/provision' ' in your deploy.rb then the provision task
# is never fire, and all of the extra hooks are ignored.
#
# It's convenient to override the provision task in your deploy.rb to do something more meaningful as well.
#
#      desc "Provision the servers"
#      task :provision do
#        utilities.apt_install "git-core telnet elinks netcat socat curl arping rsync nload wget locate strace"
#        mysql.install_client_libs #needed to build mysql2 gem
#        deploy.provision_bundler_dependencies
#      end

Capistrano::Configuration.instance(true).load do

  namespace :deploy do

    # Init all base roles so they can be empty
    roles[:web]
    roles[:app]
    roles[:db]

    # This block allows us to add items to the very beginning of provisioning
    # while allowing the consumer to freely override the deploy:provision task to add
    # thier own non-framework items.
    on :start, :only => "deploy:provision" do
      deploy.provision_prerequisites
    end

    task :provision_prerequisites do
      utilities.apt_update
      utilities.apt_install_by_command('add-apt-repository')
    end

    task :provision do
      logger.info "Provisioning Services"
    end

  end

end
