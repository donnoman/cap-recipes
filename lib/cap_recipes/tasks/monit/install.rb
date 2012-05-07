Capistrano::Configuration.instance(true).load do

  namespace :monit do

    set :monit_root, "/etc/monit"
    set :monit_default_file, "/etc/default/monit"
    set(:monit_monitrc_file) {"#{monit_root}/monitrc"}
    set :monit_monitrc_path, File.join(File.dirname(__FILE__),'monitrc')
    set :monit_path, File.dirname(__FILE__)
    set(:monit_file) {monit_root}
    set(:monit_confd) {"#{monit_root}/conf.d"}
    set :monit_mailserver, "localhost"
    set :monit_alert_email, "root@localhost"
    set :monit_from_email, "monit@localhost"
    set :monit_interval_seconds, "20"
    set :monit_start_delay_seconds, "60"

    def cmd(command)
      sudo "monit #{command}"
    end

    # Use this helper to upload monit conf.d files and reload monit
    # monit.upload dk_filter_monit_path, "dk-filter.monit"
    def upload(src,name)
      utilities.sudo_upload_template src, "#{monit_confd}/#{name}"
      monit.cmd "reload"
    end

    desc "Install Monit"
    task :install do
      utilities.apt_install "monit"
      monit.setup
    end

    desc "Install monitrc settings"
    task :setup do
      utilities.sudo_upload_template monit_monitrc_path, monit_monitrc_file, :owner => "root:root", :mode => "0700"
      utilities.sudo_upload_template File.join(monit_path,'modebug'), "#{monit_file}/modebug", :owner => "root:root", :mode => "0700"
      utilities.sudo_upload_template File.join(monit_path,'morun'), "#{monit_file}/morun", :owner => "root:root", :mode => "0700"
    end

    desc "enable monit startup"
    task :enable do
      sudo "sed -i 's/startup=.*/startup=1/g' #{monit_default_file}"
    end

    desc "disable monit startup"
    task :disable do
      sudo "sed -i 's/startup=.*/startup=0/g' #{monit_default_file}"
    end

    %w(status summary reload validate).each do |t|
      desc "monit #{t}"
      task t.to_sym do
        sudo "monit #{t}"
      end
    end

    %w(start stop restart).each do |t|
      desc "#{t} monit"
      task t.to_sym do
        sudo "/etc/init.d/monit #{t}"
      end
    end

  end
end
