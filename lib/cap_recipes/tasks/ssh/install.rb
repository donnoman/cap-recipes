# @author Rick Russell <sysadmin.rick@gmail.com>
Capistrano::Configuration.instance(true).load do

  namespace :ssh do
    set :issue_net, File.join(File.dirname(__FILE__),'issue.net')

    desc "Setup and Configure issue.net and sshd_config"
    task :install_issue do
      utilities.sudo_upload_template issue_net, "/etc/issue.net", :mode => "644", :owner => 'root:root'
      sudo %Q{sed -i "s/#*Banner.*/Banner \\\/etc\\\/issue.net/g" /etc/ssh/sshd_config }
      sudo %Q{sed -i "s/PrintLastLog yes/PrintLastLog no/g" /etc/ssh/sshd_config }
      restart
    end

    desc "Restart SSH"
    task :restart do
      sudo "service ssh restart"
    end
  end
end
