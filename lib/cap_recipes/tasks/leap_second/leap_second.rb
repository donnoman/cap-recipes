Capistrano::Configuration.instance(true).load do

  namespace :leap_second do
    desc "Fix Leap Second Bug"
    task :fix do
      run %Q{#{sudo} /etc/init.d/ntp stop && #{sudo} date -s "`date`" && #{sudo} /etc/init.d/ntp start}
    end
  end
end
