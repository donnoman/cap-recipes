Capistrano::Configuration.instance(true).load do

  namespace :jenkins do
    # left as a stub to add later for full jenkins server install
    task :install do; end
  end

  namespace :jenkins_jnlp_slave do
    # this recipe only works for a single slave at the moment because we are relying on
    # a single value in the erb for the secret.
    # you have to register the jenkins_jnlp_slave_name on your jenkins master first to get the
    # secret.
    roles[:jenkins_jnlp_slave]
    set :jenkins_jnlp_slave_root, "/var/lib/jenkins"
    set :jenkins_jnlp_slave_user, "jenkins"
    set :jenkins_jnlp_slave_init, "jnlp_slave"
    set(:jenkins_jnlp_slave_upstart_file) {"/etc/init/#{jenkins_jnlp_slave_init}.conf"}
    set :jenkins_jnlp_slave_upstart_erb, File.join(File.dirname(__FILE__),'jnlp_slave.upstart.erb')
    set :jenkins_jnlp_slave_jar_start_args, nil
    set :jenkins_jnlp_slave_java_args, "-Xmx256m -Djava.net.preferIPv4Stack=true"
    set(:jenkins_jnlp_master_url) { utilities.ask("jenkins_jnlp_master_url (http://yourserver:port)")}
    set :jenkins_jnlp_slave_name, "$(hostname -f)"
    set(:jenkins_jnlp_slave_secret) { utilities.ask("jenkins_jnlp_slave_secret")}

    desc "Install jnlp slave"
    task :install, :roles => :jenkins_jnlp_slave do
      if jenkins_jnlp_slave_secret
        utilities.apt_install "openjdk-#{openjdk_version}-jre openjdk-#{openjdk_version}-jdk"
        utilities.addgroup("#{jenkins_jnlp_slave_user};true")
        utilities.adduser(jenkins_jnlp_slave_user, :shell => "bin/false", :home => jenkins_jnlp_slave_root)
        sudo "mkdir -p #{jenkins_jnlp_slave_root}/logs"
        run "cd #{jenkins_jnlp_slave_root} && #{sudo} wget --tries=2 -c --progress=bar:force #{jenkins_jnlp_master_url}/jnlpJars/slave.jar"
        sudo "chown -R #{jenkins_jnlp_slave_user}:#{jenkins_jnlp_slave_user} #{jenkins_jnlp_slave_root}"
        utilities.sudo_upload_template jenkins_jnlp_slave_upstart_erb, jenkins_jnlp_slave_upstart_file, :owner => "root:root"
      end
    end

    %w(start stop restart).each do |t|
      desc "#{t} jenkins_jnlp_slave"
      task t.to_sym, :roles => :jenkins_jnlp_slave do
        sudo "service #{jenkins_jnlp_slave_init} #{t} "
      end
    end

  end
end
