# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :s3cmd do

    set(:s3cmd_config_path) { File.join(File.dirname(__FILE__),'s3cfg')}
    set(:aws_access_key_id) { utilities.ask('What is the AWS_ACCESS_KEY_ID?','')}
    set(:aws_secret_access_key) {utilities.ask('What is the AWS_SECRET_ACCESS_KEY?','')}
    set(:aws_encryption_password) {utilities.ask('What is the AWS_ENCRYPTION_PASSWORD?','')}
    set :root_home_path, "/root"
    set(:user_home_path) {"/home/#{user}"}

    desc "install s3cmd"
    task :install do
      run "wget -O- -q http://s3tools.org/repo/deb-all/stable/s3tools.key | #{sudo} apt-key add -"
      sudo "wget -O/etc/apt/sources.list.d/s3tools.list http://s3tools.org/repo/deb-all/stable/s3tools.list"
      utilities.apt_update
      utilities.apt_install "s3cmd"
      setup
      verify
    end

    desc "setup s3cmd"
    task :setup do
      run "#{sudo} mkdir -p #{root_home_path}"
      run "mkdir -p #{user_home_path}"
      utilities.sudo_upload_template s3cmd_config_path, "#{root_home_path}/.s3cfg", :mode => '600'
      utilities.upload_template s3cmd_config_path, "#{user_home_path}/.s3cfg", :mode => '600' unless user == 'root'
    end

    desc "verify s3cmd works"
    task :verify do
      run "s3cmd --version"
    end

  end
end
