# @author Rick Russell <sysadmin.rick@gmail.com>
Capistrano::Configuration.instance(true).load do

  namespace :pflogsumm do
    roles[:pflogsumm]
    set :pflogsumm_src, "https://raw.github.com/KTamas/pflogsumm/master/pflogsumm.pl"
    set :pflogsum_chase_report, File.join(File.dirname(__FILE__), 'reports', 'chase_daily.sh')
    set :pflogsum_att_report, File.join(File.dirname(__FILE__), 'reports', 'att_daily.sh')
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
      utilities.sudo_upload_template pflogsum_chase_report,"#{pflogsumm_scripts_dir}/chase_daily.sh", :owner => "root:root"
      utilities.sudo_upload_template pflogsum_att_report,"#{pflogsumm_scripts_dir}/att_daily.sh", :owner => "root:root"
    end

    desc "Execute Script"
    task :run_chase_report, :roles => :pflogsumm do
      sudo "sh ~/scripts/chase_daily.sh"
    end

    desc "Execute Script"
    task :run_att_report, :roles => :pflogsumm do
      sudo "sh ~/scripts/att_daily.sh"
    end

  end
end