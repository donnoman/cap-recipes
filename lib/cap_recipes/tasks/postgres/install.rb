# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :postgres do
    roles[:postgres]
    # set(:postgres_admin_username) { "postgres"}
    # set(:postgres_admin_password) { utilities.ask "postgres_admin_password:"}
    # set :postgres_bind_address, "127.0.0.1" # "0.0.0.0" for all interfaces.
    # set :postgres_conf, File.join(File.dirname(__FILE__),'my.cnf.erb')
    # set :postgres_conf_path, "/etc/postgres/my.cnf"
    # set :postgres_data_dir, "/var/lib/postgres"

    # def postgres_client_cmd(cmd,opts={})
    #   postgres_user = opts[:user] || "root"
    #   postgres_pass = opts[:pass] || (postgres_admin_password if postgres_user == "root")
    #   command = []
    #   command << "#{sudo}" if opts[:use_sudo]
    #   command << (opts[:postgres] || "postgres")
    #   command << "-u#{postgres_user}" if postgres_user
    #   command << "-p" if postgres_pass
    #   command << "-h#{opts[:host]}" if opts[:host]
    #   command << "-P#{opts[:port]}" if opts[:port]
    #   command << "--force" if opts[:force]
    #   command << "-e \"#{cmd}\"" unless cmd.nil?
    #   command = command.join(" ")
    #   utilities.run_with_input(command, /^Enter password:/, postgres_pass) if opts[:run] != false
    #   command
    # end

    desc "Install postgres-server"
    task :install, :roles => :postgres do
      utilities.apt_install "postgresql postgresql-contrib"
    end

    task :setup, :roles => [:postgres] do
    #   utilities.sudo_upload_template postgres_conf, postgres_conf_path, :mode => "644", :owner => 'root:root'
    end

    # task :set_root_password, :roles => [:postgres] do
    #   run "#{sudo} postgresadmin -u root password #{TeeLogWriter.redact(postgres_admin_password)}"
    # end

    desc "Install postgres Developement Libraries"
    task :install_client_libs, :except => {:no_release => true} do
      utilities.apt_install "postgresql-client libpq-dev"
    end

    # desc "Setup the postgres Data and Log directories"
    # task :setup_data_dir, :roles => [:postgres] do
    #   sudo "mkdir -p #{postgres_data_dir}"
    #   sudo "chown -R  postgres:postgres #{postgres_data_dir}"
    # end

  end

end
