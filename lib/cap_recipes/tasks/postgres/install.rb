# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :postgres do
    roles[:postgres]
    set(:postgres_ver) {"8.4"}
    set(:postgres_admin_username) { "postgres" }
    set(:postgres_admin_password) { nil }
    set(:postgres_username) { utilities.ask "postgres_username:" }
    set(:postgres_password) { utilities.ask "postgres_password:" }

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
    #   utilities.sudo_upload_template postgres_conf, postgres_conf_path, :mode => "644", :owner => 'root:root'
    end

    task :createuser, :roles => :postgres do
      postgres_client_cmd "CREATE USER #{postgres_username} WITH PASSWORD '#{postgres_password}' CREATEDB;", :force => true
    end

    # task :set_root_password, :roles => [:postgres] do
    #   run "#{sudo} postgresadmin -u root password #{TeeLogWriter.redact(postgres_admin_password)}"
    # end

    desc "Install postgres Developement Libraries"
    task :install_client_libs, :except => {:no_release => true} do
      utilities.apt_install "postgresql-client-#{postgres_ver} libpq-dev"
    end

    # desc "Setup the postgres Data and Log directories"
    # task :setup_data_dir, :roles => [:postgres] do
    #   sudo "mkdir -p #{postgres_data_dir}"
    #   sudo "chown -R  postgres:postgres #{postgres_data_dir}"
    # end

  end

end
