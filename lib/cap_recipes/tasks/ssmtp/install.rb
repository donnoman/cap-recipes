# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do
  # TODO: additional configuration options
  # http://tombuntu.com/index.php/2008/10/21/sending-email-from-your-system-with-ssmtp/

  namespace :ssmtp do
    roles[:ssmtp] #empty role
    set :ssmtp_domain, "localhost"
    set :ssmtp_conf_path, File.join(File.dirname(__FILE__),'ssmtp.conf')
    set(:ssmtp_root_alias) {"postmaster@#{ssmtp_domain}"}
    set :ssmtp_mailhub, ""
    set :ssmtp_rewrite_domain, ""
    set :ssmtp_hostname, ""
    set :ssmtp_from_line_override, "YES"
    set(:ssmtp_verify_email) { utilities.ask "Enter the email address to send the test to:" }

    desc 'Installs ssmtp'
    task :install, :roles => :ssmtp do
      utilities.apt_install "ssmtp mailutils"
      setup
    end

    desc "Setup ssmtp"
    task :setup, :roles => :ssmtp do
      utilities.sudo_upload_template ssmtp_conf_path, "/etc/ssmtp/ssmtp.conf"
    end

    desc "verify ssmtp"
    task :verify, :roles => :ssmtp do
      run %Q{echo "testing ssmtp on `hostname` to #{ssmtp_verify_email}" | mail -s "test ssmtp on `hostname`" #{ssmtp_verify_email}}
    end

  end
end
