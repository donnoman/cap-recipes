# @author Donovan Bray <donnoman@donovanbray.com>
Capistrano::Configuration.instance(true).load do

  namespace :ripple do
    set :ripple_template_path, File.join(File.dirname(__FILE__),'ripple.yml.template')
    set :ripple_host, "127.0.0.1" #can be an array
    set :ripple_http_port, '8098'
    set :ripple_pb_port, '8087'

    desc "Configure the Ripple Template"
    task :configure, :except => {:no_release => true} do
      utilities.sudo_upload_template ripple_template_path, "#{current_release}/config/ripple.yml"
    end

  end

end
