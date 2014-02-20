# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "cap-recipes"
  s.version = "2.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nathan Esquenazi", "Donovan Bray"]
  s.date = "2014-02-20"
  s.description = "Battle-tested capistrano provisioning recipes for debian based distributions"
  s.email = "donnoman@donovanbray.com nesquena@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.textile"
  ]
  s.files = [
    ".bundle/config",
    ".ruby-gemset.template",
    ".ruby-version.template",
    ".rvmrc.template",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.textile",
    "Rakefile",
    "VERSION.yml",
    "cap-recipes.gemspec",
    "examples/advanced/deploy.rb",
    "examples/advanced/deploy/experimental.rb",
    "examples/advanced/deploy/production.rb",
    "examples/simple/deploy.rb",
    "lib/cap_recipes.rb",
    "lib/cap_recipes/tasks/apache.rb",
    "lib/cap_recipes/tasks/apache/hooks.rb",
    "lib/cap_recipes/tasks/apache/install.rb",
    "lib/cap_recipes/tasks/apache/manage.rb",
    "lib/cap_recipes/tasks/apache/settings.rb",
    "lib/cap_recipes/tasks/apache2.rb",
    "lib/cap_recipes/tasks/apparmor.rb",
    "lib/cap_recipes/tasks/apparmor/hooks.rb",
    "lib/cap_recipes/tasks/apparmor/install.rb",
    "lib/cap_recipes/tasks/apparmor/usr.sbin.mysqld",
    "lib/cap_recipes/tasks/aptitude.rb",
    "lib/cap_recipes/tasks/aptitude/manage.rb",
    "lib/cap_recipes/tasks/autossh.rb",
    "lib/cap_recipes/tasks/autossh/autossh.sh",
    "lib/cap_recipes/tasks/autossh/hooks.rb",
    "lib/cap_recipes/tasks/autossh/install.rb",
    "lib/cap_recipes/tasks/backgroundrb.rb",
    "lib/cap_recipes/tasks/backgroundrb/hooks.rb",
    "lib/cap_recipes/tasks/backgroundrb/manage.rb",
    "lib/cap_recipes/tasks/bprobe.rb",
    "lib/cap_recipes/tasks/bprobe/bprobe.god",
    "lib/cap_recipes/tasks/bprobe/hooks.rb",
    "lib/cap_recipes/tasks/bprobe/install.rb",
    "lib/cap_recipes/tasks/bundler.rb",
    "lib/cap_recipes/tasks/bundler/hooks.rb",
    "lib/cap_recipes/tasks/bundler/install.rb",
    "lib/cap_recipes/tasks/cassandra.rb",
    "lib/cap_recipes/tasks/cassandra/hooks.rb",
    "lib/cap_recipes/tasks/cassandra/install.rb",
    "lib/cap_recipes/tasks/cassandra/manage.rb",
    "lib/cap_recipes/tasks/chef_client.rb",
    "lib/cap_recipes/tasks/chef_client/client.rb.erb",
    "lib/cap_recipes/tasks/chef_client/hooks.rb",
    "lib/cap_recipes/tasks/chef_client/install.rb",
    "lib/cap_recipes/tasks/chef_client/manage.rb",
    "lib/cap_recipes/tasks/chef_server.rb",
    "lib/cap_recipes/tasks/chef_server/client.rb.erb",
    "lib/cap_recipes/tasks/chef_server/hooks.rb",
    "lib/cap_recipes/tasks/chef_server/install.rb",
    "lib/cap_recipes/tasks/chef_server/install.sh.erb",
    "lib/cap_recipes/tasks/csgo_ds.rb",
    "lib/cap_recipes/tasks/csgo_ds/csgo_ds.init.erb",
    "lib/cap_recipes/tasks/csgo_ds/hooks.rb",
    "lib/cap_recipes/tasks/csgo_ds/install.rb",
    "lib/cap_recipes/tasks/csgo_ds/motd.txt.erb",
    "lib/cap_recipes/tasks/csgo_ds/server.cfg.erb",
    "lib/cap_recipes/tasks/csgo_ds/update_csgo.sh.erb",
    "lib/cap_recipes/tasks/datadog.rb",
    "lib/cap_recipes/tasks/datadog/datadog.conf.erb",
    "lib/cap_recipes/tasks/datadog/hooks.rb",
    "lib/cap_recipes/tasks/datadog/install.rb",
    "lib/cap_recipes/tasks/delayed_job.rb",
    "lib/cap_recipes/tasks/delayed_job/hooks.rb",
    "lib/cap_recipes/tasks/delayed_job/manage.rb",
    "lib/cap_recipes/tasks/denyhosts.rb",
    "lib/cap_recipes/tasks/denyhosts/hooks.rb",
    "lib/cap_recipes/tasks/denyhosts/install.rb",
    "lib/cap_recipes/tasks/dovecot.rb",
    "lib/cap_recipes/tasks/dovecot/dovecot.conf.erb",
    "lib/cap_recipes/tasks/dovecot/dovecot.logrotate.erb",
    "lib/cap_recipes/tasks/dovecot/hooks.rb",
    "lib/cap_recipes/tasks/dovecot/install.rb",
    "lib/cap_recipes/tasks/dphys_swapfile.rb",
    "lib/cap_recipes/tasks/dphys_swapfile/dphys-swapfile.erb",
    "lib/cap_recipes/tasks/dphys_swapfile/hooks.rb",
    "lib/cap_recipes/tasks/dphys_swapfile/install.rb",
    "lib/cap_recipes/tasks/erlang.rb",
    "lib/cap_recipes/tasks/erlang/hooks.rb",
    "lib/cap_recipes/tasks/erlang/install.rb",
    "lib/cap_recipes/tasks/git.rb",
    "lib/cap_recipes/tasks/git/hooks.rb",
    "lib/cap_recipes/tasks/git/install.rb",
    "lib/cap_recipes/tasks/gitosis.rb",
    "lib/cap_recipes/tasks/gitosis/hooks.rb",
    "lib/cap_recipes/tasks/gitosis/install.rb",
    "lib/cap_recipes/tasks/god.rb",
    "lib/cap_recipes/tasks/god/config.god",
    "lib/cap_recipes/tasks/god/contacts.god",
    "lib/cap_recipes/tasks/god/god.init",
    "lib/cap_recipes/tasks/god/god.upstart.erb",
    "lib/cap_recipes/tasks/god/god.upstart.init.erb",
    "lib/cap_recipes/tasks/god/hooks.rb",
    "lib/cap_recipes/tasks/god/install.rb",
    "lib/cap_recipes/tasks/graphite.rb",
    "lib/cap_recipes/tasks/graphite/carbon.conf",
    "lib/cap_recipes/tasks/graphite/graphite.conf",
    "lib/cap_recipes/tasks/graphite/hooks.rb",
    "lib/cap_recipes/tasks/graphite/install.rb",
    "lib/cap_recipes/tasks/graphite/storage-schemas.conf",
    "lib/cap_recipes/tasks/haproxy.rb",
    "lib/cap_recipes/tasks/haproxy/haproxy.cfg",
    "lib/cap_recipes/tasks/haproxy/haproxy.god",
    "lib/cap_recipes/tasks/haproxy/hooks.rb",
    "lib/cap_recipes/tasks/haproxy/install.rb",
    "lib/cap_recipes/tasks/hlds.rb",
    "lib/cap_recipes/tasks/hlds/hlds.init.erb",
    "lib/cap_recipes/tasks/hlds/hooks.rb",
    "lib/cap_recipes/tasks/hlds/install.rb",
    "lib/cap_recipes/tasks/hlds/motd.txt.erb",
    "lib/cap_recipes/tasks/hlds/motd_text.txt.erb",
    "lib/cap_recipes/tasks/hlds/server.cfg.erb",
    "lib/cap_recipes/tasks/hlds/steam_appid.txt.erb",
    "lib/cap_recipes/tasks/hosts.rb",
    "lib/cap_recipes/tasks/hosts/hooks.rb",
    "lib/cap_recipes/tasks/hosts/install.rb",
    "lib/cap_recipes/tasks/jenkins.rb",
    "lib/cap_recipes/tasks/jenkins/hooks.rb",
    "lib/cap_recipes/tasks/jenkins/install.rb",
    "lib/cap_recipes/tasks/jenkins/jnlp_slave.upstart.erb",
    "lib/cap_recipes/tasks/juggernaut.rb",
    "lib/cap_recipes/tasks/juggernaut/hooks.rb",
    "lib/cap_recipes/tasks/juggernaut/manage.rb",
    "lib/cap_recipes/tasks/leap_second.rb",
    "lib/cap_recipes/tasks/leap_second/leap_second.rb",
    "lib/cap_recipes/tasks/logrotate.rb",
    "lib/cap_recipes/tasks/logrotate/hooks.rb",
    "lib/cap_recipes/tasks/logrotate/install.rb",
    "lib/cap_recipes/tasks/memcache.rb",
    "lib/cap_recipes/tasks/memcache/hooks.rb",
    "lib/cap_recipes/tasks/memcache/install.rb",
    "lib/cap_recipes/tasks/memcache/manage.rb",
    "lib/cap_recipes/tasks/mongodb.rb",
    "lib/cap_recipes/tasks/mongodb/hooks.rb",
    "lib/cap_recipes/tasks/mongodb/install.rb",
    "lib/cap_recipes/tasks/mongodb/manage.rb",
    "lib/cap_recipes/tasks/monit.rb",
    "lib/cap_recipes/tasks/monit/hooks.rb",
    "lib/cap_recipes/tasks/monit/install.rb",
    "lib/cap_recipes/tasks/monit/modebug",
    "lib/cap_recipes/tasks/monit/monitrc",
    "lib/cap_recipes/tasks/monit/morun",
    "lib/cap_recipes/tasks/munin.rb",
    "lib/cap_recipes/tasks/munin/hooks.rb",
    "lib/cap_recipes/tasks/munin/install.rb",
    "lib/cap_recipes/tasks/mysql.rb",
    "lib/cap_recipes/tasks/mysql/hooks.rb",
    "lib/cap_recipes/tasks/mysql/install.rb",
    "lib/cap_recipes/tasks/mysql/manage.rb",
    "lib/cap_recipes/tasks/mysql/my.cnf.erb",
    "lib/cap_recipes/tasks/mysql/mysql.monit",
    "lib/cap_recipes/tasks/mysql/mysql_backup_outfile.sh",
    "lib/cap_recipes/tasks/mysql/mysql_backup_s3.sh",
    "lib/cap_recipes/tasks/mysql/mysql_restore.sh",
    "lib/cap_recipes/tasks/mysql/mysql_restore_outfile.sh",
    "lib/cap_recipes/tasks/mysql/tuner.rb",
    "lib/cap_recipes/tasks/mysql_master.rb",
    "lib/cap_recipes/tasks/mysql_master/default-storage-engine.cnf",
    "lib/cap_recipes/tasks/mysql_master/hooks.rb",
    "lib/cap_recipes/tasks/mysql_master/install.rb",
    "lib/cap_recipes/tasks/mysql_master/my.cnf",
    "lib/cap_recipes/tasks/mysql_master/my.cnf.old",
    "lib/cap_recipes/tasks/mysql_master/replication.cnf",
    "lib/cap_recipes/tasks/mysql_master/slave.cnf",
    "lib/cap_recipes/tasks/newrelic_rpm.rb",
    "lib/cap_recipes/tasks/newrelic_rpm/hooks.rb",
    "lib/cap_recipes/tasks/newrelic_rpm/install.rb",
    "lib/cap_recipes/tasks/newrelic_sysmond.rb",
    "lib/cap_recipes/tasks/newrelic_sysmond/hooks.rb",
    "lib/cap_recipes/tasks/newrelic_sysmond/install.rb",
    "lib/cap_recipes/tasks/newrelic_sysmond/newrelic_sysmond.god",
    "lib/cap_recipes/tasks/newrelic_sysmond/nrsysmond.cfg.erb",
    "lib/cap_recipes/tasks/nginx.rb",
    "lib/cap_recipes/tasks/nginx/app.conf",
    "lib/cap_recipes/tasks/nginx/hooks.rb",
    "lib/cap_recipes/tasks/nginx/install.rb",
    "lib/cap_recipes/tasks/nginx/manage.rb",
    "lib/cap_recipes/tasks/nginx/nginx.conf",
    "lib/cap_recipes/tasks/nginx/nginx.god",
    "lib/cap_recipes/tasks/nginx/nginx.init",
    "lib/cap_recipes/tasks/nginx/nginx.logrotate",
    "lib/cap_recipes/tasks/nginx/stub_status.conf",
    "lib/cap_recipes/tasks/nginx_passenger.rb",
    "lib/cap_recipes/tasks/nginx_passenger/app.conf",
    "lib/cap_recipes/tasks/nginx_passenger/hooks.rb",
    "lib/cap_recipes/tasks/nginx_passenger/install.rb",
    "lib/cap_recipes/tasks/nginx_passenger/manage.rb",
    "lib/cap_recipes/tasks/nginx_passenger/nginx.conf",
    "lib/cap_recipes/tasks/nginx_passenger/nginx_passenger.god",
    "lib/cap_recipes/tasks/nginx_passenger/nginx_passenger.init",
    "lib/cap_recipes/tasks/nginx_passenger/stub_status.conf",
    "lib/cap_recipes/tasks/nginx_unicorn.rb",
    "lib/cap_recipes/tasks/nginx_unicorn/app.conf",
    "lib/cap_recipes/tasks/nginx_unicorn/hooks.rb",
    "lib/cap_recipes/tasks/nginx_unicorn/install.rb",
    "lib/cap_recipes/tasks/nginx_unicorn/manage.rb",
    "lib/cap_recipes/tasks/nginx_unicorn/mime.types.erb",
    "lib/cap_recipes/tasks/nginx_unicorn/nginx.conf",
    "lib/cap_recipes/tasks/nginx_unicorn/nginx_unicorn.god",
    "lib/cap_recipes/tasks/nginx_unicorn/nginx_unicorn.init",
    "lib/cap_recipes/tasks/nginx_unicorn/nginx_unicorn.logrotate",
    "lib/cap_recipes/tasks/nginx_unicorn/stub_status.conf",
    "lib/cap_recipes/tasks/nodejs.rb",
    "lib/cap_recipes/tasks/nodejs/hooks.rb",
    "lib/cap_recipes/tasks/nodejs/install.rb",
    "lib/cap_recipes/tasks/nrpe.rb",
    "lib/cap_recipes/tasks/nrpe/hooks.rb",
    "lib/cap_recipes/tasks/nrpe/install.rb",
    "lib/cap_recipes/tasks/nrpe/nrpe.cfg.erb",
    "lib/cap_recipes/tasks/openjdk/hooks.rb",
    "lib/cap_recipes/tasks/openjdk/install.rb",
    "lib/cap_recipes/tasks/passenger.rb",
    "lib/cap_recipes/tasks/passenger/hooks.rb",
    "lib/cap_recipes/tasks/passenger/install.rb",
    "lib/cap_recipes/tasks/passenger/manage.rb",
    "lib/cap_recipes/tasks/pflogsumm.rb",
    "lib/cap_recipes/tasks/pflogsumm/hooks.rb",
    "lib/cap_recipes/tasks/pflogsumm/install.rb",
    "lib/cap_recipes/tasks/pflogsumm/reports/postfix_daily_stats.sh",
    "lib/cap_recipes/tasks/phantomjs.rb",
    "lib/cap_recipes/tasks/phantomjs/hooks.rb",
    "lib/cap_recipes/tasks/phantomjs/install.rb",
    "lib/cap_recipes/tasks/postfix.rb",
    "lib/cap_recipes/tasks/postfix/hooks.rb",
    "lib/cap_recipes/tasks/postfix/install.rb",
    "lib/cap_recipes/tasks/postfix/manage.rb",
    "lib/cap_recipes/tasks/provision.rb",
    "lib/cap_recipes/tasks/provision/empty_roles.rb",
    "lib/cap_recipes/tasks/provision/manage.rb",
    "lib/cap_recipes/tasks/provision/task_once.rb",
    "lib/cap_recipes/tasks/rails.rb",
    "lib/cap_recipes/tasks/rails/hooks.rb",
    "lib/cap_recipes/tasks/rails/manage.rb",
    "lib/cap_recipes/tasks/redis.rb",
    "lib/cap_recipes/tasks/redis/hooks.rb",
    "lib/cap_recipes/tasks/redis/install.rb",
    "lib/cap_recipes/tasks/redis/manage.rb",
    "lib/cap_recipes/tasks/redis/redis-cli-config.sh",
    "lib/cap_recipes/tasks/redis/redis-slave.conf",
    "lib/cap_recipes/tasks/redis/redis.conf",
    "lib/cap_recipes/tasks/redis/redis.god",
    "lib/cap_recipes/tasks/redis/redis.init",
    "lib/cap_recipes/tasks/redis/redis.logrotate",
    "lib/cap_recipes/tasks/redis/redis_backup_s3.sh",
    "lib/cap_recipes/tasks/ree.rb",
    "lib/cap_recipes/tasks/ree/hooks.rb",
    "lib/cap_recipes/tasks/ree/install.rb",
    "lib/cap_recipes/tasks/resque.rb",
    "lib/cap_recipes/tasks/resque/hooks.rb",
    "lib/cap_recipes/tasks/resque/install.rb",
    "lib/cap_recipes/tasks/resque/resque.yml.template",
    "lib/cap_recipes/tasks/resque/resque_worker.god",
    "lib/cap_recipes/tasks/riak.rb",
    "lib/cap_recipes/tasks/riak/app.config",
    "lib/cap_recipes/tasks/riak/hooks.rb",
    "lib/cap_recipes/tasks/riak/install.rb",
    "lib/cap_recipes/tasks/riak/riak.god",
    "lib/cap_recipes/tasks/riak/riak.init",
    "lib/cap_recipes/tasks/riak/riak.monit",
    "lib/cap_recipes/tasks/riak/vm.args",
    "lib/cap_recipes/tasks/ripple.rb",
    "lib/cap_recipes/tasks/ripple/hooks.rb",
    "lib/cap_recipes/tasks/ripple/install.rb",
    "lib/cap_recipes/tasks/ripple/ripple.yml.template",
    "lib/cap_recipes/tasks/ruby.rb",
    "lib/cap_recipes/tasks/ruby/hooks.rb",
    "lib/cap_recipes/tasks/ruby/install.rb",
    "lib/cap_recipes/tasks/ruby19.rb",
    "lib/cap_recipes/tasks/ruby19/hooks.rb",
    "lib/cap_recipes/tasks/ruby19/install.rb",
    "lib/cap_recipes/tasks/rubygems.rb",
    "lib/cap_recipes/tasks/rubygems/hooks.rb",
    "lib/cap_recipes/tasks/rubygems/install.rb",
    "lib/cap_recipes/tasks/rubygems/manage.rb",
    "lib/cap_recipes/tasks/s3cmd.rb",
    "lib/cap_recipes/tasks/s3cmd/hooks.rb",
    "lib/cap_recipes/tasks/s3cmd/install.rb",
    "lib/cap_recipes/tasks/s3cmd/s3cfg",
    "lib/cap_recipes/tasks/s3fs.rb",
    "lib/cap_recipes/tasks/s3fs/hooks.rb",
    "lib/cap_recipes/tasks/s3fs/install.rb",
    "lib/cap_recipes/tasks/s3fs/manage.rb",
    "lib/cap_recipes/tasks/s3fs/s3fs-mount",
    "lib/cap_recipes/tasks/s3sync.rb",
    "lib/cap_recipes/tasks/s3sync/hooks.rb",
    "lib/cap_recipes/tasks/s3sync/install.rb",
    "lib/cap_recipes/tasks/s3sync/s3config.yml",
    "lib/cap_recipes/tasks/sdagent.rb",
    "lib/cap_recipes/tasks/sdagent/hooks.rb",
    "lib/cap_recipes/tasks/sdagent/install.rb",
    "lib/cap_recipes/tasks/sdagent/manage.rb",
    "lib/cap_recipes/tasks/sdagent/sdagent.god",
    "lib/cap_recipes/tasks/ssh.rb",
    "lib/cap_recipes/tasks/ssh/hooks.rb",
    "lib/cap_recipes/tasks/ssh/install.rb",
    "lib/cap_recipes/tasks/ssh/issue.net",
    "lib/cap_recipes/tasks/ssh/vagrant",
    "lib/cap_recipes/tasks/ssmtp.rb",
    "lib/cap_recipes/tasks/ssmtp/hooks.rb",
    "lib/cap_recipes/tasks/ssmtp/install.rb",
    "lib/cap_recipes/tasks/ssmtp/ssmtp.conf",
    "lib/cap_recipes/tasks/statsd.rb",
    "lib/cap_recipes/tasks/statsd/hooks.rb",
    "lib/cap_recipes/tasks/statsd/install.rb",
    "lib/cap_recipes/tasks/statsd/statsd.god",
    "lib/cap_recipes/tasks/statsd/statsd.init.sh",
    "lib/cap_recipes/tasks/statsd/statsd.js",
    "lib/cap_recipes/tasks/stingray.rb",
    "lib/cap_recipes/tasks/stingray/configure.recording.erb",
    "lib/cap_recipes/tasks/stingray/hooks.rb",
    "lib/cap_recipes/tasks/stingray/install.rb",
    "lib/cap_recipes/tasks/stingray/install.recording.erb",
    "lib/cap_recipes/tasks/teelogger.rb",
    "lib/cap_recipes/tasks/teelogger/teelogger.rb",
    "lib/cap_recipes/tasks/thinking_sphinx.rb",
    "lib/cap_recipes/tasks/thinking_sphinx/hooks.rb",
    "lib/cap_recipes/tasks/thinking_sphinx/install.rb",
    "lib/cap_recipes/tasks/thinking_sphinx/manage.rb",
    "lib/cap_recipes/tasks/ufw.rb",
    "lib/cap_recipes/tasks/ufw/hooks.rb",
    "lib/cap_recipes/tasks/ufw/install.rb",
    "lib/cap_recipes/tasks/unicorn.rb",
    "lib/cap_recipes/tasks/unicorn/hooks.rb",
    "lib/cap_recipes/tasks/unicorn/install.rb",
    "lib/cap_recipes/tasks/unicorn/unicorn.god",
    "lib/cap_recipes/tasks/unicorn/unicorn.rb.erb",
    "lib/cap_recipes/tasks/utilities.rb",
    "lib/cap_recipes/tasks/whenever.rb",
    "lib/cap_recipes/tasks/whenever/hooks.rb",
    "lib/cap_recipes/tasks/whenever/manage.rb",
    "lib/cap_recipes/tasks/wkhtmltopdf.rb",
    "lib/cap_recipes/tasks/wkhtmltopdf/hooks.rb",
    "lib/cap_recipes/tasks/wkhtmltopdf/install.rb",
    "lib/cap_recipes/tasks/xtrabackup.rb",
    "lib/cap_recipes/tasks/xtrabackup/hooks.rb",
    "lib/cap_recipes/tasks/xtrabackup/innobackupex-full.sh.erb",
    "lib/cap_recipes/tasks/xtrabackup/innobackupex-restore.sh.erb",
    "lib/cap_recipes/tasks/xtrabackup/install.rb",
    "lib/cap_recipes/tasks/xtrabackup/mini_backup_full.sh",
    "lib/cap_recipes/tasks/xtrabackup/mini_restore_full.sh",
    "lib/cap_recipes/tasks/xtrabackup/percona.list",
    "spec/cap/all/Capfile",
    "spec/cap/helper.rb",
    "spec/cap_recipes_spec.rb",
    "spec/spec_helper.rb",
    "spec/tasks/teelogger_spec.rb"
  ]
  s.homepage = "http://github.com/donnoman/cap-recipes"
  s.require_paths = ["lib"]
  s.rubyforge_project = "cap-recipes"
  s.rubygems_version = "1.8.25"
  s.summary = "Battle-tested capistrano provisioning recipes for debian based distributions"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<capistrano>, ["~> 2.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6"])
      s.add_development_dependency(%q<rake>, ["~> 0.9.2"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<psych>, ["~> 2.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.14.0"])
      s.add_development_dependency(%q<debugger>, [">= 0"])
    else
      s.add_dependency(%q<capistrano>, ["~> 2.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6"])
      s.add_dependency(%q<rake>, ["~> 0.9.2"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<psych>, ["~> 2.0"])
      s.add_dependency(%q<rspec>, ["~> 2.14.0"])
      s.add_dependency(%q<debugger>, [">= 0"])
    end
  else
    s.add_dependency(%q<capistrano>, ["~> 2.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6"])
    s.add_dependency(%q<rake>, ["~> 0.9.2"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<psych>, ["~> 2.0"])
    s.add_dependency(%q<rspec>, ["~> 2.14.0"])
    s.add_dependency(%q<debugger>, [">= 0"])
  end
end

