# @author Rick Russell <sysadmin.rick@gmail.com>
Capistrano::Configuration.instance(true).load do

  namespace :pflogsumm do
    roles[:pflogsumm]
    set :pflogsumm_src, "https://raw.github.com/KTamas/pflogsumm/master/pflogsumm.pl"
    set :pflogsumm_report, File.join(File.dirname(__FILE__), 'reports', 'postfix_daily_stats.sh')
    set :pflogsumm_scripts_dir, "/root/scripts"
    set :pflogsumm_reports_dir, "/var/log/reports"

    def cmd(opts={})
      day = opts[:day] || 'today'
      target = opts[:target] || 'mail'
      syslog_name = opts[:syslog_name] || 'postfix'
      logfile = "pflogsumm-#{target}.log"
      run %Q{ #{sudo} pflogsumm -q -u 0 --problems_first --no_no_msg_size --syslog_name=#{syslog_name} -d #{day} /var/log/#{target}.log /var/log/#{target}.log.1 > /tmp/#{logfile} }
      top.get "/tmp/#{logfile}", "log/#{logfile}", :via => :scp
      File.open("log/#{logfile}", "r") do |infile|
        while (line = infile.gets)
          logger.info line
        end
      end
    end

    desc "setup pflogsum"
    task :setup, :roles => :pflogsumm do
      pflogsumm.install
      pflogsumm.upload_report_scripts
    end

    desc "Setup pflogsumm"
    task :install, :roles => :pflogsumm do
      run "cd /usr/local/bin && #{sudo} wget --tries=2 -c --progress=bar:force #{pflogsumm_src}"
      sudo "mv /usr/local/bin/pflogsumm.pl /usr/local/bin/pflogsumm && #{sudo} chmod 755 /usr/local/bin/pflogsumm"
      run "cd /usr/bin && #{sudo} ln -f -s /usr/local/bin/pflogsumm"
    end

    desc "Mailgraph and rrdtool"
    task :install_mailgraph, :roles => :pflogsumm do
      utilities.apt_install "rrdtool mailgraph"
    end

    desc "Upload report scripts"
    task :upload_report_scripts, :roles => :pflogsumm do
      sudo "mkdir -p #{pflogsumm_scripts_dir} #{pflogsumm_reports_dir}"
      utilities.sudo_upload_template pflogsumm_report,"#{pflogsumm_scripts_dir}/postfix_daily_stats.sh", :mode => "755", :owner => "root:root"
    end

    desc "Execute Script"
    task :daily_report, :roles => :pflogsumm do
      run "#{sudo} #{pflogsumm_scripts_dir}/postfix_daily_stats_report.sh"
    end

  end
end
