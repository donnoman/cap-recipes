# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :postgres do
    roles[:postgres]
    set :postgres_ver, "8.4"
    set :postgres_admin_username, "postgres"
    set :postgres_admin_password, nil
    set(:postgres_username) { utilities.ask "postgres_username:" }
    set(:postgres_password) { utilities.ask "postgres_password:" }
    set(:postgres_database) { utilities.ask "postgres_database:" }
    set(:postgres_databases) { [postgres_database].flatten }

    def postgres_client_cmd(cmd,opts={})
      postgres_user = opts[:user] || postgres_admin_username
      postgres_pass = opts[:pass] || (postgres_admin_password if postgres_user == postgres_admin_username)
      command = []
      command << "#{sudo :as => postgres_user}"
      command << (opts[:psql] || "psql")
      command << "-U #{postgres_user}" if postgres_user
      command << "-W" if postgres_pass
      command << "-h #{opts[:host]}" if opts[:host]
      command << "-p #{opts[:port]}" if opts[:port]
      command << "-c \"#{cmd}\"" unless cmd.nil?
      command << ";true" if opts[:force]
      command = command.join(" ")
      utilities.run_with_input(command, /^Password/, postgres_pass)
    end

    desc "Install postgres-server"
    task :install, :roles => :postgres do
      utilities.apt_install "postgresql-#{postgres_ver} postgresql-contrib-#{postgres_ver}"
    end

    task :setup, :roles => [:postgres] do
      #no-op on purpose, nothing to do yet.
    end

    task :createuser, :roles => :postgres do
      postgres_client_cmd "CREATE USER #{postgres_username} WITH PASSWORD '#{postgres_password}' CREATEDB;", :force => true
    end

    task :createdatabase do
      createdatabases
    end

    task :createdatabases, :roles => :postgres do
      postgres_databases.each do |db|
        postgres_client_cmd "CREATE DATABASE #{db};", :force => true
      end
    end

    task :setdatabaseowner, :roles => :postgres do
      postgres_client_cmd "ALTER DATABASE #{postgres_database} OWNER TO #{postgres_username};"
    end

    desc "Install postgres Developement Libraries"
    task :install_client_libs, :except => {:no_release => true} do
      utilities.apt_install "postgresql-client-#{postgres_ver} libpq-dev"
    end

  end

end
