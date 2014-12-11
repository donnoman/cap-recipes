# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :postgres do

    %w(start stop restart).each do |t|
      desc "#{t} postgres"
      task t.to_sym, :roles => :postgres do
        sudo "service postgresql-#{postgres_ver} #{t}"
      end
    end

  end
end
