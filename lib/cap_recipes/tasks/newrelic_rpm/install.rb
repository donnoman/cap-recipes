# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do
  namespace :newrelic_rpm do
    roles[:newrelic_rpm]
    set(:newrelic_rpm_license_key) {utilities.ask("newrelic_rpm_license_key:")}


    desc "Notify New Relic so the deploys will appear in the time series graphs."
    task :notice_deployment do
      # https://docs.newrelic.com/docs/ruby/recording-deployments-with-the-ruby-agent#Manual
      newrelic deployments 
    end

  end
end
