# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :datadog do
    roles[:datadog]
    set(:datadog_license_key) {utilities.ask("datadog_license_key:")}

    desc 'Installs datadog'
    task :install, :roles => :datadog do
      run "#{sudo} apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7A7DA52"
      sudo %Q{#{sudo} sh -c "echo 'deb http://apt.datadoghq.com/ unstable main' > /etc/apt/sources.list.d/datadog.list"}
      utilities.apt_install 'datadog-agent'
    end

    desc "Setup datadog"
    task :setup, :roles => :datadog do
      sudo %Q{#{sudo} sh -c "sed 's/api_key:.*/api_key: #{datadog_license_key}/' /etc/dd-agent/datadog.conf.example > /etc/dd-agent/datadog.conf"}
    end

    %w(start stop restart).each do |t|
      desc "#{t} datadog-agent"
      task t.to_sym, :roles => :datadog do
        sudo "/etc/init.d/datadog-agent #{t}"
      end
    end

  end
end
