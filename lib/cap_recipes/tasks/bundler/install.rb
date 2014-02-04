# @author Donovan Bray <donnoman@donovanbray.com>
require File.expand_path(File.dirname(__FILE__) + '/../utilities')

Capistrano::Configuration.instance(:must_exist).load do

  namespace :bundler do

    # Intelligent Bundler Handling, requires no rollbacks
    # Each release gets their own bundle seeded from the last built bundle
    # to make the deploys faster, and the running application doesn't
    # get its bundle changed out from under it.

    set :bundler_opts, %w(--deployment --no-color --quiet)
    set(:bundler_exec) { base_ruby_path + "/bin/bundle" }
    set(:bundler_dir) { "#{shared_path}/bundle" }
    set(:bundler_deploy_dir) { "#{latest_release}/vendor/bundle" }
    set :bundler_rubygems_minimum_ver, "1.8.25"
    set(:bundler_ver_latest) { JSON.parse(open("https://rubygems.org/api/v1/gems/bundler.json").read)['version'] }
    set(:bundler_ver) { utilities.suggest_version(:bundler_ver, bundler_ver_latest) }
    set :bundler_user, nil # don't use sudo by default.
    set :bundler_file, "Gemfile"
    set :bundler_binstubs, true
    set :bundler_clean, true
    set :rake, "bundle exec rake"

    def bundle(path=nil)
      # Don't bother if there's no gemfile.
      # optionally do it as a specific user to avoid permissions problems
      # do as much as possible in a single 'run' for speed.
      # had to remove the bundle check in order to always create the binstubs
      # use the save_bundle task to 'memorialize' a good bundle
      args = bundler_opts.dup
      args << "--path #{path}" unless path.to_s.empty? || bundler_opts.include?("--system")
      args << "--gemfile=#{bundler_file}" unless bundler_file == "Gemfile"
      args << "--binstubs" if bundler_binstubs
      args << "--clean" if bundler_clean && bundler_ver >= "1.3.0"
      cmd = "cd #{latest_release}; if [ -f #{bundler_file} ]; then #{bundler_exec} install #{args.join(' ')}; fi"
      if bundler_opts.include?('--system')
        cmd = "#{sudo} sh -c '#{cmd}'"
      elsif bundler_user and not bundler_user.empty?
        cmd = "sudo -u #{bundler_user} sh -c '#{cmd}'"
      end
      utilities.run_with_input(cmd, /yes\/no/, "yes\n") # If prompted with git authenticity of host respond affirmatively.
    end

    desc "Update Rubygems to be compatible with bundler"
    task :update_rubygems, :except => { :no_release => true } do
      gem_ver = capture("#{base_ruby_path}/bin/gem --version 2> /dev/null").chomp
      if gem_ver < bundler_rubygems_minimum_ver
        logger.important "RubyGems needs to be udpated, has gem --version #{gem_ver}"
        run "#{sudo} #{base_ruby_path}/bin/gem update --system #{bundler_rubygems_minimum_ver} || #{sudo} #{base_ruby_path}/bin/gem update --system" #if pinned version fails update to the latest.
      end
    end

    desc "Setup system to use bundler"
    task :install, :except => { :no_release => true } do
      update_rubygems
      utilities.gem_install_only "bundler", bundler_ver
    end

    desc "Save the bundle to initialize the next bundle run"
    task :save_bundle, :except => {:no_release => true } do
      run "rm -rf #{bundler_dir}; cp -r #{bundler_deploy_dir} #{bundler_dir}"
    end

    desc "bundle the deploy"
    task :configure, :except => {:no_release => true} do
      run "mkdir -p #{bundler_dir}; rm -rf #{bundler_deploy_dir}; cp -r #{bundler_dir} #{bundler_deploy_dir}; rm -rf #{latest_release}/.bundle/config"
      bundle bundler_deploy_dir
    end

    desc "delete the bundle cache dir"
    task :reset_cache, :except => {:no_release => true} do
      run "rm -rf #{bundler_dir}"
    end

  end

end
