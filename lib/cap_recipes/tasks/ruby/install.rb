require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :ruby do

    desc "install ruby"
    task :install, :roles => :app do
      utilities.apt_install %w[ruby ri rdoc ruby1.8-dev irb1.8 libreadline-ruby1.8
            libruby1.8 rdoc1.8 ri1.8 ruby1.8 irb libopenssl-ruby libopenssl-ruby1.8]
    end
    task :setup do
      #TODO: remove this task
      logger.info " update your scripts ruby:setup is now ruby:install"
      install
    end

  end
end
