# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do
  namespace :newrelic_rpm do
    #this variable is for compatability with newrelic_nrsysmond, it's not used directly here.
    set(:newrelic_rpm_license_key) {utilities.ask("newrelic_rpm_license_key:")}
    set(:newrelic_rpm_cli) { "bundle exec newrelic" }
    set(:newrelic_rpm_source_benchmark_revision) { previous_revision }
    set(:newrelic_rpm_source_changes_command) {
      case scm
      when :git
        %Q{#{source.command} --no-pager log #{newrelic_rpm_source_benchmark_revision}..#{latest_revision} --no-color --merges --pretty=format:"%s - %an, %ad : %H"}
      else
        %Q{echo "no changes command implemented."}
      end
    }

    desc "Notify New Relic so the deploys will appear in the time series graphs."
    task :notice_deployment, :except => { :no_release => true }, :once => true do
      # https://docs.newrelic.com/docs/ruby/recording-deployments-with-the-ruby-agent#Manual
      # The return of this command is coerced to true because we don't want any failure in
      # noticing a deployment to break the deploy.
      run "cd #{latest_release} && #{newrelic_rpm_source_changes_command} | #{newrelic_rpm_cli} deployments --environment=#{rails_env} --revision=#{latest_revision} --changes; true"
    end

  end
end
