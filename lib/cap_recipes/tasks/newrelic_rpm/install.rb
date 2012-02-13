# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do
  namespace :newrelic_rpm do
    roles[:newrelic_rpm]
    set(:newrelic_rpm_license_key) {utilities.ask("newrelic_rpm_license_key:")}
  end
end
