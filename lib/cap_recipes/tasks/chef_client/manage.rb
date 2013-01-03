###############################################################################
# CHEF-CLIENT MANAGE
################################################################################
require 'ostruct'

Capistrano::Configuration.instance(true).load do

  namespace :chef do
    namespace :client do

      def with_report(servers, headers, &block)
        raise "You must supply a block to 'with_report'!" if !block_given?

        results = Array.new
        max_lengths = OpenStruct.new
        servers.each do |server|
          results << block.call(server)
        end

        headers.each do |header|
          maximum = [headers.collect{ |header| header.to_s }, results.collect{ |result| result.send(header.to_sym).to_s }].flatten.map(&:length).max
          max_lengths.send("#{header}=", maximum)
        end

        puts("-" * (max_lengths.send(:table).values.reduce(:+) + (max_lengths.send(:table).keys.count * 2)))
        headers.each do |header|
          print("  %#{max_lengths.send(header)}s" % [header.to_s.upcase])
        end
        print("\n")
        puts("-" * (max_lengths.send(:table).values.reduce(:+) + (max_lengths.send(:table).keys.count * 2)))

        results.each do |result|
          headers.each do |header|
            print("  %#{max_lengths.send(header)}s" % [result.send(header)])
          end
          print("\n")
        end
        puts("-" * (max_lengths.send(:table).values.reduce(:+) + (max_lengths.send(:table).keys.count * 2)))
      end

      desc "start chef-client"
      task :start, :roles => [:chef_client] do
        logger.info("#" * 80)
        logger.info("# CHEF-CLIENT START")
        logger.info("#" * 80)
        sudo("bash -c '([[ -f /etc/init.d/chef-client ]] && /etc/init.d/chef-client start) || echo \"NOT INSTALLED!\"'")
      end

      desc "stop chef-client"
      task :stop, :roles => [:chef_client] do
        logger.info("#" * 80)
        logger.info("# CHEF-CLIENT STOP")
        logger.info("#" * 80)
        sudo("bash -c '([[ -f /etc/init.d/chef-client ]] && /etc/init.d/chef-client stop) || echo \"NOT INSTALLED!\"'")
      end

      desc "restart chef-client"
      task :restart, :roles => [:chef_client] do
        logger.info("#" * 80)
        logger.info("# CHEF-CLIENT RESTART")
        logger.info("#" * 80)
        sudo("bash -c '([[ -f /etc/init.d/chef-client ]] && /etc/init.d/chef-client restart) || echo \"NOT INSTALLED!\"'")
      end

      desc "chef-client status"
      task :status, :roles => [:chef_client] do
        with_report(find_servers_for_task(current_task), [:hostname, :ip, :chef_client_version, :chef_client_status]) do |server|
          logger.info("#" * 80)
          logger.info("# CHEF-CLIENT STATUS: #{server}")
          logger.info("#" * 80)

          server_hostname = capture("hostname -f", :hosts => server).strip
          chef_client_status = capture("#{sudo} bash -c '([[ -f /etc/init.d/chef-client ]] && /etc/init.d/chef-client status) || echo \"NOT INSTALLED!\"'", :hosts => server).strip
          chef_client_version = capture("#{sudo} bash -c '([[ -f /etc/init.d/chef-client ]] && /usr/bin/chef-client -v) || echo \"NOT INSTALLED!\"'", :hosts => server).strip

          OpenStruct.new(:hostname => server_hostname, :ip => server.to_s, :chef_client_status => chef_client_status, :chef_client_version => chef_client_version)
        end
      end

      desc "chef-client key backup"
      task :backup, :roles => [:chef_client] do
        raise "You must specify a CHEF_ENV for this command!" if (ENV['CHEF_ENV'].nil? || ENV['CHEF_ENV'].blank?)
        with_report(find_servers_for_task(current_task), [:hostname, :ip, :chef_client_version, :chef_client_status, :key_backup_result]) do |server|
          logger.info("#" * 80)
          logger.info("# CHEF-CLIENT KEY BACKUP: #{server}")
          logger.info("#" * 80)

          server_hostname = capture("hostname -f", :hosts => server).strip
          chef_client_status = capture("#{sudo} bash -c '([[ -f /etc/init.d/chef-client ]] && /etc/init.d/chef-client status) || echo \"NOT INSTALLED!\"'", :hosts => server).strip
          chef_client_version = capture("#{sudo} bash -c '([[ -f /etc/init.d/chef-client ]] && /usr/bin/chef-client -v) || echo \"NOT INSTALLED!\"'", :hosts => server).strip

          to_filepath = File.expand_path(File.join(Dir.pwd, ".chef", "chef-#{ENV['CHEF_ENV'].downcase}-client-#{server_hostname}.pem"))
          sudo("cp -v /etc/chef/client.pem /var/tmp/client.pem && chown -v dev:dev /var/tmp/client.pem", :hosts => server)
          (top.download("/var/tmp/client.pem", to_filepath, :hosts => server) rescue nil)
          sudo("rm -fv /var/tmp/client.pem", :hosts => server)
          key_backup_result = ((File.exists?(to_filepath) && (File.mtime(to_filepath).utc > (Time.now.utc - 15.seconds))) ? "SUCCESS" : "X")

          OpenStruct.new(:hostname => server_hostname, :ip => server.to_s, :chef_client_status => chef_client_status, :chef_client_version => chef_client_version, :key_backup_result => key_backup_result)
        end
      end

    end
  end

end
