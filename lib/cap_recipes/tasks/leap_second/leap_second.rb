Capistrano::Configuration.instance(true).load do
    
  namespace :leap_second do
    roles[:app]

    desc "Fix Leap Second Bug"
    task :fix, :roles => [:app, :jenkins_master, :jenkins_slave] do
      sudo "sudo /etc/init.d/ntp stop && sudo date -s "`date`" && sudo /etc/init.d/ntp start"
    end
  end
end