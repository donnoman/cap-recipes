# @author Rick Russell <sysadmin.rick@gmail.com>

Capistrano::Configuration.instance(true).load do

  namespace :csgo_ds do

    roles[:csgo_ds]
    set :steamcmd_app_root, "/opt/steamapps"
    set(:csgo_ds_source) { "#{steamcmd_app_root}/csgo_ds" }
    set :steamcmd_user, "steam"
    set(:user) { "#{steamcmd_user}" }
    set :steamcmd_wget_url, "http://media.steampowered.com/client/steamcmd_linux.tar.gz"
    set :csgo_ds_init_erb, File.join(File.dirname(__FILE__),'csgo_ds.init.erb')
    set :csgo_ds_init_erb_dest, '/etc/init.d/csgo_ds'
    set :csgo_ds_config_erb, File.join(File.dirname(__FILE__),'GameModes_Server.txt.erb')
    set :csgo_ds_motd_txt_erb, File.join(File.dirname(__FILE__),'motd.txt.erb')
    set(:csgo_ds_config_root) {"#{steamcmd_app_root}/cfg"}
    set(:csgo_ds_config_server_cfg) {"#{csgo_ds_config_root}/server.cfg"}
    set(:csgo_ds_parameters) {"./srcds_run -game ${GAME_NAME} -console -usercon -ip ${GAME_IP} -port ${GAME_PORT} +fps_max ${GAME_FPS} +game_type ${GAME_TYPE} +game_mode ${GAME_MODE} +map ${GAME_MAP} -autoupdate -steam_dir ${STEAMCMD}"}
    set :csgo_ds_game, "csgo"
    set :fps_max, "1000"
    set :maxplayers, "24"
    set :server_ip, "0.0.0.0"
    set :server_port, "27015"
    set :csgo_ds_mapcycle, %w(cs_italy de_dust de_aztec cs_office de_dust2 de_train de_inferno de_nuke)
    set :csgo_ds_motd, "Welcome to a CS:GO Dedicated Server!"
    set :csgo_ds_config_hostname, "CS:GO Dedicated Server"
    set :csgo_ds_config_sv_contact, "unset"
    set :csgo_ds_config_sv_region, "1"  # -1 is the world, 0 is USA east coast, 1 is USA west coast 2 south america, 3 europe, 4 asia, 5 australia, 6 middle east, 7 africa
    set(:csgo_ds_config_rcon_password) {utilities.ask("rcon_password")}
    set :csgo_ds_config_sv_password, nil # connect password
    set :csgo_ds_config_tf_server_identity_account_id, nil
    set :csgo_ds_config_tf_server_identity_token, nil

    set(:default_packages) {
      case target_os
      when :debian64, :debian32
        "build-essential gcc-multilib"
      when :ubuntu64, :ubuntu32
        "build-essential"
      else
        raise Capistrano::Error "Unhandled target_os in :default_packages"
      end
    }

    task :install_steamcmd, :roles => :csgo_ds do
      run "#{sudo} mkdir -p #{csgo_ds_source} #{steamcmd_app_root}"
      utilities.addgroup "#{steamcmd_user};true"
      utilities.adduser "#{steamcmd_user}" , :group => "#{steamcmd_user}"
      utilities.apt_update
      utilities.apt_install "#{default_packages}"
      run "cd #{steamcmd_app_root} && #{sudo} wget --tries=2 -c --progress=bar:force #{steamcmd_wget_url} && #{sudo} tar -xvzf steamcmd_linux.tar.gz"
      run "#{sudo} chown -R #{steamcmd_user}:#{steamcmd_user} #{steamcmd_app_root}"
    end

    task :install_csgo, :roles => :csgo_ds do
      run "cd #{steamcmd_app_root} && ./steamcmd.sh +login anonymous +force_install_dir #{csgo_ds_source} +app_update 740 validate +quit"
    end

    task :update_csgo, :roles => :csgo_ds do
      run "cd #{csgo_ds_source} && #{sudo} ./app_update 740"
      run "#{sudo} chown -R #{steamcmd_user}:#{steamcmd_user} #{csgo_ds_source}"
    end

    task :setup, :roles => :csgo_ds do
      utilities.sudo_upload_template csgo_ds_init_erb, csgo_ds_init_erb_dest, :owner => "root:root", :mode => "700"
      utilities.sudo_upload_template csgo_ds_motd_txt_erb, "#{csgo_ds_source}/csgo/motd.txt", :owner => "#{steamcmd_user}:#{steamcmd_user}"
      run "#{sudo} chown -R #{steamcmd_user}:#{steamcmd_user} #{csgo_ds_source}"
    end

    %w(start stop restart).each do |t|
      task t.to_sym, :roles => [:csgo_ds, :csgo_ds_ugc] do
        run "#{sudo} /etc/init.d/csgo_ds #{t}"
      end
    end

  end
end