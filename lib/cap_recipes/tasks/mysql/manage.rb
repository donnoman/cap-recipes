# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :mysql do

    %w(start stop restart).each do |t|
      desc "#{t} mysql"
      task t.to_sym, :roles => :db do
        sudo "service mysql #{t}"
      end
    end

  end
end
