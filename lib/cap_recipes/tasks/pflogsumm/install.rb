# @author Rick Russell <sysadmin.rick@gmail.com>
Capistrano::Configuration.instance(true).load do

  namespace :pflogsumm do
    roles[:pflogsumm]
    set :pflogsumm_src, "https://raw.github.com/KTamas/pflogsumm/master/pflogsumm.pl"
    set :pflogsumm_report, File.join(File.dirname(__FILE__), 'reports', 'postfix_daily_stats.sh')
    set :pflogsumm_scripts_dir, "/root/scripts"
    set :pflogsumm_reports_dir, "/var/log/reports"

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
      sudo "mkdir -p #{pflogsumm_scripts_dir}"
      sudo "mkdir -p #{pflogsumm_reports_dir}"
      utilities.sudo_upload_template pflogsumm_report,"#{pflogsumm_scripts_dir}/postfix_daily_stats.sh", :mode => "755", :owner => "root:root"
    end

    desc "Execute Script"
    task :daily_report, :roles => :pflogsumm do
      sudo "sh ~/scripts/postfix_daily_stats_report.sh"
    end

  end
end