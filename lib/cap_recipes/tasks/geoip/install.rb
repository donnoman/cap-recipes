# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :geoip do

    set(:geoip_user_id)     { utilities.ask('GeoIP UserId?') }
    set(:geoip_license_key) { utilities.ask('GeoIP LicenseKey?') }
    set(:geoip_product_ids) { utilities.ask('GeoIP ProductIds?') }
    set(:geoip_conf_erb) { File.join(File.dirname(__FILE__),'GeoIP.conf.erb') }
    set(:geoip_cron_erb) { File.join(File.dirname(__FILE__),'geoip.cron.erb') }
    set :geoip_database_dir, "/usr/share/GeoIP"

    desc "install geoip support"
    task :install, :except => {:no_release => true } do
      utilities.apt_install "geoip-bin libgeoip-dev"
      run "#{sudo} mkdir -p #{geoip_database_dir}"
      setup
      update
    end

    desc "setup geoip cron"
    task :setup, :except => {:no_release => true } do
      utilities.sudo_upload_template geoip_conf_erb, "/etc/GeoIP.conf", :owner => "root:root", :mode => "600"
      utilities.sudo_upload_template geoip_cron_erb, "/etc/cron.d/geoip", :owner => "root:root", :mode => "600"
    end

    desc "update geoip"
    task :update, :except => {:no_release => true } do
      run %Q{#{sudo} bash -c "geoipupdate -d #{geoip_database_dir}";true}
    end

  end
end

