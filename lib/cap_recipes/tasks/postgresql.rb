# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/utilities')

# This Nginx is targeted for the :app role meant to be acting as a front end
# to a unicorn based application

# Additions
# https://github.com/newobj/nginx-x-rid-header
# https://github.com/yaoweibin/nginx_syslog_patch

# Possible Future Additions
# https://support.newrelic.com/kb/features/tracking-front-end-time

  
Capistrano::Configuration.instance(true).load do
  
  
  set :postgresql_host, "localhost"
  set :postgresql_user, application
  set(postgresql_password) {"bundio5842"}
  set(postgresql_database) {"#{application}_production"}
  set(postgresql_dump_path) {"#{current_path}/tmp"}
  set(postgresql_dump_file) {"#{application}_dump.sql"}
  set(postgresql_local_dump_path) {File.expand_path("../../../tmp", __FILE__) }
  set(postgresql_pid) {"/var/run/postgresql/9.2-main.pid"}
  
  namespace :postgresql do
  desc "Install the latest stable release of PostgreSQL."
  task :install, roles: :db, only: {primary: true} do
    run "#{sudo} add-apt-repository -y ppa:pitti/postgresql"
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install postgresql libpq-dev"
  end
  after "postgresql:install", "postgresql:create_database"

  desc "Create a database for this application."
  task :create_database, roles: :db, only: {primary: true} do
    run %Q{#{sudo} -u postgres psql -c "create user #{postgresql_user} with password '#{postgresql_password}';"}
    run %Q{#{sudo} -u postgres psql -c "create database #{postgresql_database} owner #{postgresql_user};"}
  end
  after "deploy:setup", "postgresql:install"

  desc "Generate the database.yml configuration file."
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "postgresql.yml.erb", "#{shared_path}/config/database.yml"
  end
  after "postgresql:create_database", "postgresql:setup"

  desc "Symlink the database.yml file into latest release"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "postgresql:symlink"

  desc "database console"
  task :console do
    auth = capture "cat #{shared_path}/config/database.yml"
    puts "PASSWORD::: #{auth.match(/password: (.*$)/).captures.first}"
    hostname = find_servers_for_task(current_task).first
    exec "ssh #{hostname} -t 'source ~/.zshrc && psql -U #{application} #{postgresql_database}'"
  end


  namespace :local do
    desc "Download remote database to tmp/"
    task :download do
      dumpfile = "#{postgresql_local_dump_path}/#{postgresql_dump_file}.gz"
      get "#{postgresql_dump_path}/#{postgresql_dump_file}.gz", dumpfile
    end

    desc "Restores local database from temp file"
    task :restore do
      auth = YAML.load_file(File.expand_path('../../database.yml', __FILE__))
      dev  = auth['development']
      user, pass, database, host = dev['username'], dev['password'], dev['database'], dev['host']
      dumpfile = "#{postgresql_local_dump_path}/#{postgresql_dump_file}"
      system "gzip -cd #{dumpfile}.gz > #{dumpfile} && cat #{dumpfile} | psql -U #{user} -h #{host} #{database}"
    end

    desc "Dump remote database and download it locally"
    task :localize do
      remote.dump
      download
    end

    desc "Dump remote database, download it locally and restore local database"
    task :sync do
      localize
      restore
    end
  end

  namespace :remote do
    desc "Dump remote database"
    task :dump do
      dbyml = capture "cat #{shared_path}/config/database.yml"
      info  = YAML.load dbyml
      db    = info[stage.to_s]
      user, pass, database, host = db['username'], db['password'], db['database'], db['host']
      commands = <<-CMD
        pg_dump -U #{user} -h #{host} #{database} | \
        gzip > #{postgresql_dump_path}/#{postgresql_dump_file}.gz
      CMD
      run commands do |ch, stream, data|
        if data =~ /Password/
          ch.send_data("#{pass}\n")
        end
      end
    end

    desc "Uploads local sql.gz file to remote server"
    task :upload do
      dumpfile = "#{postgresql_local_dump_path}/#{postgresql_dump_file}.gz"
      upfile   = "#{postgresql_dump_path}/#{postgresql_dump_file}.gz"
      put File.read(dumpfile), upfile
    end

    desc "Restores remote database"
    task :restore do
      dumpfile = "#{postgresql_dump_path}/#{postgresql_dump_file}"
      gzfile   = "#{dumpfile}.gz"
      dbyml    = capture "cat #{shared_path}/config/database.yml"
      info     = YAML.load dbyml
      db       = info['production']
      user, pass, database, host = db['username'], db['password'], db['database'], db['host']

      commands = <<-CMD
        gzip -cd #{gzfile} > #{dumpfile} && \
        cat #{dumpfile} | \
        psql -U #{user} -h #{host} #{database}
      CMD

      run commands do |ch, stream, data|
        if data =~ /Password/
          ch.send_data("#{pass}\n")
        end
      end
    end

    desc "Uploads and restores remote database"
    task :sync do
      upload
      restore
    end
  end
  end
end
