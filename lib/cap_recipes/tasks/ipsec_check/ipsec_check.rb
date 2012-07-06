Capistrano::Configuration.instance(true).load do

  namespace :ipsec_check do

    set :ipsec_check_sh_local, File.join(File.dirname(__FILE__), "ipsec_check.erb")
    set :ipsec_check_sh_remote, "/usr/local/sbin/ipsec_check.sh"

    set :ipsec_check_cron_d_entry, "*/3 * * * * root [ -x #{ipsec_check_sh_remote} ] && #{ipsec_check_sh_remote} >/dev/null 2>&1\n"
    set :ipsec_check_cron_d_file, "/etc/cron.d/ipsec-check"
    set :ipsec_check_cron_d_tmp_file, "/tmp/ipsec-check"

    set :ipsec_restart_command, "/etc/init.d/ipsec restart"

    desc "Install ipsec-check"
    task :install, :roles => [:app] do

      # ensure /usr/local/sbin exists
      run "#{sudo} mkdir -p /usr/local/sbin"

      # and it is owned by root:root
      run "#{sudo} chown root:root /usr/local/sbin"

      # upload our script and ensure it is owned by root:root and has the executable bit set
      utilities.sudo_upload_template(ipsec_check_sh_local, ipsec_check_sh_remote, :owner => "root:root", :mode => "0744")

      # upload and move in our cron.d entry
      put ipsec_check_cron_d_entry, ipsec_check_cron_d_tmp_file
      run "#{sudo} mv #{ipsec_check_cron_d_tmp_file} #{ipsec_check_cron_d_file}"

      # ensure root:root owns it and it has 0644 permissions
      run "#{sudo} chown root:root #{ipsec_check_cron_d_file}"
      run "#{sudo} chmod 0644 #{ipsec_check_cron_d_file}"
    end

  end
end
