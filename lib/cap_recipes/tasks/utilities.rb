require 'fileutils'
require 'open3'
require 'json'
require 'open-uri'

module Utilities
  # utilities.config_gsub('/etc/example', /(.*)/im, "\\1")
  def config_gsub(file, find, replace)
    tmp="/tmp/#{File.basename(file)}"
    get file, tmp
    content=File.open(tmp).read
    content.gsub!(find,replace)
    put content, tmp
    sudo "mv #{tmp} #{file}"
  end

  # utilities.ask('What is your name?', 'John')
  def ask(question, default='')
    question = "\n" + question.join("\n") if question.respond_to?(:uniq)
    answer = Capistrano::CLI.ui.ask(space(question)).strip
    answer.empty? ? default : answer
  end

  # utilities.suggest_version(:ruby_ver, 'ruby-2.1.0')
  def suggest_version(config_var,suggestion)
    ver = utilities.ask("#{config_var}: [#{suggestion}] ?",suggestion)
    logger.info %Q{*** To pin your provision to this version you should add "set :#{config_var}, '#{ver}'" to your deploy.rb}
    ver
  end

  # utilities.yes?('Proceed with install?')
  def yes?(question)
    question = "\n" + question.join("\n") if question.respond_to?(:uniq)
    question += ' (y/n)'
    ask(question).downcase.include? 'y'
  end

  def gem_install_preamble
    "#{base_ruby_path}/bin/gem install #{capture('gem -v').chomp[0] < "2" ? '-y' : ''} --no-rdoc --no-ri"
  end

  # Uses the base ruby path to install gem(s), avoids installing the gem if it's already installed.
  # Installs the gems detailed in +package+, selecting version +version+ if
  # specified.
  def gem_install(package, version=nil)
    tries = 3
    begin
      cmd = "#{sudo} #{gem_install_preamble} #{version ? '-v '+version.to_s : ''} #{package}"
      wrapped_cmd = "if ! #{base_ruby_path}/bin/gem list '#{package}' | grep --silent -e '#{package}.*#{version}'; then #{cmd}; fi"
      run wrapped_cmd
      #send(run_method,wrapped_cmd)
    rescue Capistrano::Error
      tries -= 1
      retry if tries > 0
    end
  end

  # Installs the gems detailed in +package+, selecting version +version+ if
  # specified, after uninstalling all versions of previous gems of +package+
  def gem_install_only(package, version=nil)
    tries = 3
    begin
      run "if ! #{base_ruby_path}/bin/gem list '#{package}' | grep --silent -e '#{package} \(#{version}\)'; then #{sudo} #{base_ruby_path}/bin/gem uninstall --ignore-dependencies --executables --all #{package}; #{sudo} #{gem_install_preamble} #{version ? '-v '+version.to_s : ''} #{package}; fi"
    rescue Capistrano::Error
      tries -= 1
      retry if tries > 0
    end
  end

  # uninstalls the gems detailed in +package+, selecting version +version+ if
  # specified, otherwise all.
  def gem_uninstall(package, version=nil)
    cmd = "#{sudo} #{base_ruby_path}/bin/gem uninstall --ignore-dependencies --executables #{version ? '-v '+version.to_s  : '--all'} #{package}"
    run "if #{base_ruby_path}/bin/gem list '#{package}' | grep --silent -e '#{package}.*#{version}'; then #{cmd}; fi"
  end

  def aptitude_safe_upgrade
    cmd = "#{sudo} dpkg --configure -a" #recover from previous failures.
    run_with_input(cmd, input_query=/(<No>|\?)/, "N\n")
    run "#{sudo} aptitude update"
    #using every trick in the book to attempt to force it to not prompt.
    cmd = "#{sudo} DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND=noninteractive aptitude safe-upgrade -o Aptitude::Delete-Unused=false -o Aptitude::CmdLine::Fix-Broken=true --quiet --assume-yes --target-release `lsb_release -cs`"
    run_with_input(cmd, input_query=/(<No>|\?)/, "N\n") #attempt to answer ncurses overwrite popup like when libpam complains about local modifications.
  end

  # 10.04 <=> 12.04 naming compatability layer, find packages by executable name instead of package name.
  # like add-apt-repository is in python-software-properties for 10.04 but software-properties-common in 12.04.
  #
  # utilities.apt_install_by_command('add-apt-repository')
  def apt_install_by_command(command)
    sudo_run_compressed %Q{
      #{apt_get_preamble} install apt-file;
      apt-file update;
      #{apt_get_preamble} install `apt-file --non-interactive --package-only search #{command}`
    }
  end


  # Install a package from a ppa utilizing add-apt-repository syntax
  #
  # utilities.apt_install_from_ppa("ppa:git-core/ppa","git-core")
  def apt_install_from_ppa(ppa,package)
    apt_install_by_command('add-apt-repository')
    # 12.04 has a -y, 10.04 doesn't. (the check assumes all boxes are the same)
    run "#{sudo} add-apt-repository #{capture("lsb_release -rs") < "12.04" ? "" : "-y" } #{ppa}"
    apt_update
    apt_install package
  end



  # utilities.apt_install %w[package1 package2]
  # utilities.apt_install "package1 package2"
  def apt_install(packages)
    packages = packages.split(/\s+/) if packages.respond_to?(:split)
    packages = Array(packages)
    sudo "#{apt_get_preamble} install #{packages.join(" ")}"
  end

  # utilities.apt_reinstall %w[package1 package2]
  # utilities.apt_reinstall "package1 package2"
  def apt_reinstall(packages)
    packages = packages.split(/\s+/) if packages.respond_to?(:split)
    packages = Array(packages)
    sudo "#{apt_get_preamble} --reinstall install #{packages.join(" ")}"
  end

  # remove is identical to install except that packages are removed instead of installed. Note the
  # removing a package leaves its configuration files in system. If a plus sign is appended to the
  # package name (with no intervening space), the identified package will be installed instead of
  # removed.
  def apt_remove(packages)
    packages = packages.split(/\s+/) if packages.respond_to?(:split)
    packages = Array(packages)
    sudo "#{apt_get_preamble} remove #{packages.join(" ")}"
  end

  #purge is identical to remove except that packages are removed and purged (any configuration files are deleted too).
  def apt_purge(packages)
    packages = packages.split(/\s+/) if packages.respond_to?(:split)
    packages = Array(packages)
    sudo "#{apt_get_preamble} purge #{packages.join(" ")}"
  end

  def apt_autoremove
    sudo "#{apt_get} -qy autoremove"
  end

  def apt_fix_missing
    sudo "#{apt_get} -qy update --fix-missing"
  end

  def apt_update
    sudo "#{apt_get} -qy update"
  end

  def apt_upgrade
    sudo_with_input "dpkg --configure -a", /\?/, "\n" #recover from failed dpkg
    sudo "#{apt_get} -qy update"
    sudo_with_input "#{apt_get_preamble} upgrade", /\?/, "\n" #answer the default if any package pops up a warning
  end

  def apt_get
    "DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND=noninteractive apt-get"
  end

  def apt_get_preamble
    "#{apt_get} -qyu --force-yes"
  end

  # utilities.sudo_upload('/local/path/to/file', '/remote/path/to/destination', options)
  def sudo_upload(from, to, options={}, &block)
    top.upload from, "/tmp/#{File.basename(to)}", options, &block
    sudo "mv /tmp/#{File.basename(to)} #{to}", options
    sudo "chmod #{options[:mode]} #{to}", options if options[:mode]
    sudo "chown #{options[:owner]} #{to}", options if options[:owner]
  end

  # Upload a file, running it through ERB
  # utilities.sudo_upload_template('/local/path/to/file','remote/path/to/destination', options)
  def sudo_upload_template(src,dst,options = {})
    raise Capistrano::Error, "sudo_upload_template requires Source and Destination" if src.nil? or dst.nil?
    put ERB.new(File.read(src),nil,'-').result(binding), "/tmp/#{File.basename(dst)}", options
    sudo "mv /tmp/#{File.basename(dst)} #{dst}", options
    sudo "chmod #{options[:mode]} #{dst}", options if options[:mode]
    sudo "chown #{options[:owner]} #{dst}", options if options[:owner]
  end

  # Upload a file running it through ERB
  def upload_template(src,dst,options = {})
    raise Capistrano::Error, "put_template requires Source and Destination" if src.nil? or dst.nil?
    put ERB.new(File.read(src)).result(binding), dst, options
  end

  # utilities.adduser('deploy')
  def adduser(user, options={})
    options[:shell] ||= '/bin/bash' # new accounts on ubuntu 6.06.1 have been getting /bin/sh
    switches = ""
    switches += " --system" if options[:system]
    switches += ' --disabled-password --gecos ""'
    switches += " --home #{options[:home]}" if options[:home]
    switches += " --disabled-login" if options[:disabled_login]
    switches += " --shell=#{options[:shell]} " if options[:shell] && !options[:system]
    switches += ' --no-create-home ' if options[:nohome]
    switches += " --uid #{options[:uid]} " if options[:uid]
    switches += " --gid #{options[:gid]} " if options[:gid]
    switches += " --ingroup #{options[:group]} " unless options[:group].nil?
    invoke_command "grep '^#{user}:' /etc/passwd || sudo /usr/sbin/adduser #{switches} #{user}",
    :via => run_method
  end

  # utilities.deluser('deploy')
  def deluser(user, options={})
    switches = '--force'
    switches += " --backup" if options[:backup]
    switches += " --quiet" if options[:quiet]
    switches += " --remove-home" if options[:removehome]
    switches += " --group #{options[:group]} " unless options[:group].nil?
    invoke_command "sudo /usr/sbin/deluser #{switches} #{user}",
    :via => run_method
  end

  #utilities.addgroup('deploy')
  def addgroup(group,options={})
    switches = ''
    switches += " --system" if options[:system]
    switches += " --gid #{options[:gid]} " if options[:gid]
    invoke_command "/usr/sbin/addgroup  #{switches} #{group}", :via => run_method
  end

  #utilities.delgroup('deploy')
  def delgroup(group,options={})
    switches = '--force'
    switches += " --only-if-empty" if options[:ifempty]
    invoke_command "/usr/sbin/delgroup #{switches} #{group}", :via => run_method
  end

  # role = :app
  def with_role(role, &block)
    original, ENV['HOSTS'] = ENV['HOSTS'], find_servers(:role => role).map{|d| d.host}.join(",")
    begin
      yield
    ensure
      ENV['HOSTS'] = original
    end
  end

  # role = :app
  def without_role(role, &block)
    original, ENV['HOSTS'] = ENV['HOSTS'], (find_servers() - find_servers(:roles => role)).map{|d| d.host}.join(",")
    begin
      yield
    ensure
      ENV['HOSTS'] = original
    end
  end

  # utilities.with_credentials(:user => 'xxxx', :password => 'secret')
  # options = { :user => 'xxxxx', :password => 'xxxxx' }
  def with_credentials(options={}, &block)
    original_username, original_password = user, password
    begin
      set :user,     options[:user] || original_username
      set :password, options[:password] || original_password
      yield
    ensure
      set :user,     original_username
      set :password, original_password
    end
  end

  def space(str)
    "\n#{'=' * 80}\n#{str}"
  end

  ##
  # Run a command and ask for input when input_query is seen.
  # Sends the response back to the server.
  #
  # +input_query+ is a regular expression that defaults to /^Password/.
  # Can be used where +run+ would otherwise be used.
  # run_with_input 'ssh-keygen ...', /^Are you sure you want to overwrite\?/
  def run_with_input(shell_command, input_query=/^Password/, response=nil)
    handle_command_with_input(:run, shell_command, input_query, response)
  end

  ##
  # Run a command using sudo and ask for input when a regular expression is seen.
  # Sends the response back to the server.
  #
  # See also +run_with_input+
  # +input_query+ is a regular expression
  def sudo_with_input(shell_command, input_query=/^Password/, response=nil)
    handle_command_with_input(:sudo, shell_command, input_query, response)
  end

  def invoke_with_input(shell_command, input_query=/^Password/, response=nil)
    handle_command_with_input(run_method, shell_command, input_query, response)
  end

  ##
  # Run a long bash command thats indented with appropriate ';' that allow the linefeeds to be stripped and make a single concise shell command
  #
  # utilities.run_compressed %Q{
  #   cd /usr/local/src;
  #   if [ -d "#{mysql_tuner_name}" ]; then
  #     git pull;
  #   else
  #     git clone #{mysql_tuner_src_url} #{mysql_tuner_name};
  #   fi
  # }
  def run_compressed(cmd)
    run cmd.split("\n").reject(&:empty?).map(&:strip).join(' ')
  end

  def sudo_run_compressed(cmd)
    sudo compressed_join(cmd)
  end

  def compressed_join(cmd)
     %Q{sh -c "#{cmd.split("\n").reject(&:empty?).map(&:strip).join(' ')}"}
  end

  ##
  # Checkout something from a git repo, update it if it's already checked out, and checkout the right ref.
  #   This will leave the checkout on the 'deploy' branch.
  #
  # utilities.sudo_git_clone_or_pull "git://github.com/scalarium/server-density-plugins.git", "/usr/local/src/scalarium"
  #
  # Had to change from using sudo to the deploying user because
  def git_clone_or_pull(repo,dest,ref="master")
    run "#{sudo} mkdir -p #{File.dirname(dest)}; #{sudo} chown -R #{user} #{File.dirname(dest)}"
    cmd = compressed_join %Q{
      if [ -d #{dest} ]; then
        cd #{dest};
        git fetch;
      else
        git clone #{repo} #{dest};
        cd #{dest};
        git checkout -b deploy;
      fi
    }
    run_with_input(cmd,%r{\(yes/no\)}, "yes\n")
    run_compressed %Q{
      if [ `cd #{dest} && git tag | grep -c #{ref}` = '1' ]; then
        cd #{dest}; git reset --hard #{ref};
      else
        cd #{dest}; git reset --hard origin/#{ref};
      fi
    }
  end

  ##
  # return the directory that holds the capfile
  def caproot
    File.dirname(capfile)
  end

  # logs the command then executes it locally.
  # streams the command output
  def stream_locally(cmd,opts={})
    shell = opts[:shell] || 'bash'
    tee = opts[:tee]
    redact = opts[:redact]
    redact_replacement = opts[:redact_replacment] || '-REDACTED-'
    cmd = [shell,'-c "',cmd.gsub(/"/,'\"'),'" 2>&1'].join(' ')
    cmd_text = redact ? redact.inject(cmd.inspect){|ct,r| ct.gsub(r,redact_replacement)} : cmd.inspect
    logger.trace %Q{executing locally: #{cmd_text}} if logger
    $stdout.sync = true
    elapsed = Benchmark.realtime do
      Open3.popen3(cmd) do |stdin, out, err, external|
        # Create a thread to read from each stream
        { :out => out, :err => err }.each do |key, stream|
          Thread.new do
            until (line = stream.gets).nil? do
              redact.each {|r| line.gsub!(r,redact_replacement)} if redact
              $stdout << line
              File.open(tee,'a') {|f| f.write(line) } if tee
            end
          end
        end
        # Don't exit until the external process is done
        external.join
      end
      if $?.to_i > 0 # $? is command exit code (posix style)
        raise Capistrano::LocalArgumentError, "Command #{cmd_text} returned status code #{$?}"
      end
    end
    $stdout.sync = false
    logger.trace "\ncommand finished in #{(elapsed * 1000).round}ms" if logger
  end

  private

  ##
  # Find the location of the capfile you can use this to identify a path relative to the capfile.
  def capfile
    previous = nil
    current  = File.expand_path(Dir.pwd)

    until !File.directory?(current) || current == previous
      filename = File.join(current, 'Capfile')
      return filename if File.file?(filename)
      current, previous = File.expand_path("..", current), current
    end
  end

  ##
  # Does the actual capturing of the input and streaming of the output.
  #
  # local_run_method: run or sudo
  # shell_command: The command to run
  # input_query: A regular expression matching a request for input: /^Please enter your password/
  def handle_command_with_input(local_run_method, shell_command, input_query, response=nil)
    send(local_run_method, shell_command, {:pty => true}) do |channel, stream, data|
      if data =~ input_query
        if response
          logger.info "#{data} #{"*"*(rand(10)+5)}", channel[:host]
          channel.send_data "#{response}\n"
        else
          logger.info data, channel[:host]
          response = ::Capistrano::CLI.password_prompt "#{data}"
          channel.send_data "#{response}\n"
        end
      else
        logger.info data, channel[:host]
      end
    end
  end

  ##
  # Use to raise warnings about deprecated items
  # set(:var_no_longer_used) {utilities.deprecated(:var_no_longer_used,:var_that_should_be_used)}
  def deprecated(name,replacement=nil)
    raise Capistrano::Error, "#{name} is deprecated, #{replacement ? "see: #{replacment}" : "no replacement" }."
  end



end

Capistrano.plugin :utilities, Utilities
