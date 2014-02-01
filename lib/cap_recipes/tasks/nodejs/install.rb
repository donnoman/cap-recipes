# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do

  namespace :nodejs do

    desc "Install nodejs"
    task :install, :except => {:no_release => true} do
      utilities.apt_install "nodejs"
    end

  end

end
