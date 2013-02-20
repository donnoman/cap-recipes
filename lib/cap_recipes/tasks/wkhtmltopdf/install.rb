# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :wkhtmltopdf do
    roles[:wkhtmltopdf]
    set :wkhtmltopdf_name, "wkhtmltopdf-0.9.9-static-amd64"
    set(:wkhtmltopdf_src) {"http://wkhtmltopdf.googlecode.com/files/#{wkhtmltopdf_name}.tar.bz2"}

    desc 'Installs nginx for web'
    task :install, :roles => [:wkhtmltopdf] do
      utilities.apt_install "openssl build-essential xorg libssl-dev libxrender-dev"
      sudo "mkdir -p /usr/local/src/wkhtmltopdf"
      run "cd /usr/local/src/wkhtmltopdf && #{sudo} wget --tries=2 -c --progress=bar:force #{wkhtmltopdf_src}"
      run "cd /usr/local/src/wkhtmltopdf && #{sudo} bunzip2 --force #{wkhtmltopdf_name}.tar.bz2"
      run "cd /usr/local/src/wkhtmltopdf && #{sudo} tar -xvf #{wkhtmltopdf_name}.tar"
      sudo "cp /usr/local/src/wkhtmltopdf/wkhtmltopdf-amd64 /usr/local/bin/wkhtmltopdf-amd64"
      sudo "ln -sf /usr/local/bin/wkhtmltopdf-amd64 /usr/local/bin/wkhtmltopdf"
      sudo "ln -sf /usr/local/bin/wkhtmltopdf-amd64 /usr/bin/wkhtmltopdf"
    end

  end

end
