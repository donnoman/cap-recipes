# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(true).load do

  namespace :stingray do
    roles[:stingray]
    # https://support.riverbed.com/software/stingray/trafficmanager.htm
    # must be the local path to the downloaded .tgz file. ie: in your deploy.rb to look into a tarballs directory under deploy.rb
    # I also suggest gitignoring the tarballs directory, to prevent bloating your repo.
    #   set :stingray_tarball, File.expand_path(File.join('..','tarballs',"ZeusTM_93_Linux-x86_64.tgz"),__FILE__)
    set :stingray_tarball, nil
    set :stingray_root, "/usr/local/zeus"
    set(:stingray_src_path) { "#{stingray_root}/src" }
    set(:stingray_pkg) { File.basename(stingray_tarball) }
    set(:stingray_pkg_dir) { File.join(stingray_src_path,File.basename(stingray_pkg,'.tgz')) }
    set :stingray_install_recording_erb, File.join(File.dirname(__FILE__),'install.recording.erb')
    set :stingray_configure_recording_erb, File.join(File.dirname(__FILE__),'configure.recording.erb')
    set :stingray_serial_number, nil
    set :stingray_features, nil

    # stingray_license_file_erb must be the local path to the license file file.
    #   set :stingray_license_file_erb, File.expand_path(File.join('..','licenses','developer.lic.erb'),__FILE__)
    set :stingray_license_file_erb, nil

    desc "Install Zeus Stingray"
    task :install, :roles => :stingray do
      if stingray_tarball #dont even bother if this pre-req isn't met.
        run "#{sudo} mkdir -p #{stingray_src_path}"
        top.upload stingray_tarball, "/tmp/#{stingray_pkg}"
        run "#{sudo} mv /tmp/#{stingray_pkg} #{stingray_src_path}"
        run "cd #{stingray_src_path} && #{sudo} tar -zxvf #{stingray_pkg}"
        utilities.sudo_upload_template stingray_install_recording_erb, "#{stingray_root}/#{File.basename(stingray_install_recording_erb,'.erb')}"
        run "cd #{stingray_pkg_dir} && #{sudo} ./zinstall --noninteractive --force-install-same --replay-from=#{stingray_root}/#{File.basename(stingray_install_recording_erb,'.erb')}"
      end
    end

    desc "Setup Zeus Stingray"
    task :setup, :roles => :stingray do
      if stingray_license_file_erb
        utilities.sudo_upload_template stingray_configure_recording_erb, "#{stingray_root}/#{File.basename(stingray_configure_recording_erb,'.erb')}"
        utilities.sudo_upload_template stingray_license_file_erb, "#{stingray_root}/#{File.basename(stingray_license_file_erb,'.erb')}"
        logger.info %Q{
          # When you wish to perform the initial configuration, please run (as root):
          #   #{stingray_root}/zxtm/configure --nostart --replay-from=#{stingray_root}/#{File.basename(stingray_configure_recording_erb,'.erb')}
        }
      end
    end

    desc "Retrieve fingerprint for Zeus Stingray"
    task :fingerprint, :roles => :stingray do
      sudo "#{stingray_root}/admin/bin/cert -f fingerprint -in #{stingray_root}/admin/etc/admin.public"
    end

    %w(start stop restart).each do |t|
      desc "#{t} Zeus Stingray"
      task t.to_sym, :roles => :stingray do
        run "#{sudo} service #{t} zeus"
      end
    end

  end
end
