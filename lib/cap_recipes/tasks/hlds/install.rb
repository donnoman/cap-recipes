# @author Donovan Bray <donnoman@donovanbray.com>

Capistrano::Configuration.instance(true).load do

  namespace :hlds do 

    roles[:hlds]
    set :hlds_root, "/opt/hlds"
    set(:hlds_source) {hlds_root}
    set :hlds_user, "hlds"
    set :hlds_update_tool_url, "http://storefront.steampowered.com/download/hldsupdatetool.bin"
    set(:hlds_bindir) { "#{hlds_root}/orangebox"}
    set :hlds_init_erb, File.join(File.dirname(__FILE__),'hlds.init.erb')
    set :hlds_init_dest, '/etc/init.d/hlds'
    set :hlds_config_erb, File.join(File.dirname(__FILE__),'server.cfg.erb')
    set :hlds_motd_txt_erb, File.join(File.dirname(__FILE__),'motd.txt.erb')
    set :hlds_motd_text_txt_erb, File.join(File.dirname(__FILE__),'motd_text.txt.erb')
    set :ugc_files, nil
    set(:hlds_config_root) {"#{hlds_root}/orangebox/tf/cfg"}
    set(:hlds_config_server_cfg) {"#{hlds_config_root}/server.cfg"}
    set(:hlds_parameters) {"-autoupdate +maxplayers #{maxplayers} +ip #{server_ip} -port #{server_port} +exec #{server_type_cfg} +map #{hlds_mapcycle.first} +fps_max #{fps_max}"}
    set :hlds_game, "tf"
    set :fps_max, "1000"
    set :maxplayers, "24"
    set :server_ip, "0.0.0.0"
    set :server_port, "27015"
    set :server_type_cfg, "server.cfg" # "server.cfg"
    set :hlds_mapcycle, %w(ctf_turbine pl_hoodoo ctf_2fort cp_dustbowl koth_nucleus)
    set :hlds_motd, "welcome"
    set :hlds_config_hostname, "TF2 Server"
    set :hlds_config_sv_contact, "unset"
    set :hlds_config_sv_region, "1"  # -1 is the world, 0 is USA east coast, 1 is USA west coast 2 south america, 3 europe, 4 asia, 5 australia, 6 middle east, 7 africa
    set(:hlds_config_rcon_password) {utilities.ask("rcon_password")}
    set :hlds_config_sv_password, nil # connect password
    set :hlds_config_tf_server_identity_account_id, nil
    set :hlds_config_tf_server_identity_token, nil

    set(:hlds_packages) {
      case target_os
      when :debian64, :debian32
        "build-essential gcc-multilib"
      when :ubuntu64, :ubuntu32
        "build-essential"
      else
        raise Capistrano::Error "Unhandled target_os in :hlds_packages"
      end
    }

    task :install, :roles => :hlds do
      run "#{sudo} mkdir -p #{hlds_source} #{hlds_root}"
      utilities.addgroup "#{hlds_user};true"
      utilities.adduser "hlds" , :group => "hlds"
      utilities.apt_update
      utilities.apt_install "#{hlds_packages}"
      run "cd #{hlds_source} && #{sudo} wget --tries=2 -c --progress=bar:force #{hlds_update_tool_url} && #{sudo} chmod +x hldsupdatetool.bin"
      utilities.run_with_input "cd #{hlds_source} && #{sudo} ./hldsupdatetool.bin", /decline:/, "yes\n"
      tries = 0
      begin
        run "cd #{hlds_source} && #{sudo} ./steam"
      rescue
        tries += 1
        retry if tries <= 5
      end
      run "#{sudo} chown -R #{hlds_user}:#{hlds_user} #{hlds_root}"
      setup_ugc
    end

    task :setup, :roles => :hlds do
      utilities.sudo_upload_template hlds_init_erb, hlds_init_dest, :owner => "root:root", :mode => "700"
      utilities.sudo_upload_template hlds_config_erb, hlds_config_server_cfg, :owner => "#{hlds_user}:#{hlds_user}"
      utilities.sudo_upload_template hlds_motd_txt_erb, "#{hlds_bindir}/tf/motd.txt", :owner => "#{hlds_user}:#{hlds_user}"
      utilities.sudo_upload_template hlds_motd_text_txt_erb, "#{hlds_bindir}/tf/motd_text.txt", :owner => "#{hlds_user}:#{hlds_user}"
      put hlds_mapcycle.join("\n")+"\n", "/tmp/mapcycle.txt", :owner => "#{hlds_user}:#{hlds_user}"
      run "#{sudo} cp #{hlds_bindir}/tf/mapcycle.txt #{hlds_bindir}/tf/mapcycle.txt.`date +%s`"
      run "#{sudo} mv /tmp/mapcycle.txt #{hlds_bindir}/tf/mapcycle.txt"
    end

    task :setup_ugc, :roles => :hlds_ugc do
        utilities.sudo_upload_template ugc_files, "#{hlds_config_root}/ugc.tar", :owner => "#{hlds_user}:#{hlds_user}", :mode => "755"
        run "#{sudo} tar -xf #{hlds_config_root}/ugc.tar -C #{hlds_config_root}"
        sudo "chown -R #{hlds_user}:#{hlds_user} #{hlds_config_root}"
        sudo "rm #{hlds_config_root}/ugc.tar"
    end

    task :update, :roles => :hlds do
      run "cd #{hlds_source} && #{sudo} ./steam -command update -game #{hlds_game} -dir #{hlds_root}"
      run "#{sudo} chown -R #{hlds_user}:#{hlds_user} #{hlds_root}"
    end

    %w(start stop restart).each do |t|
      task t.to_sym, :roles => [:hlds, :hlds_ugc] do
        run "#{sudo} /etc/init.d/hlds #{t}"
      end
    end

  end
end