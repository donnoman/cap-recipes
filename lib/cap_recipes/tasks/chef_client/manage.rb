###############################################################################
# CHEF-CLIENT MANAGE
################################################################################
Capistrano::Configuration.instance(true).load do

  namespace :chef do
    namespace :client do

      desc "start chef-client"
      task :start, :roles => [:chef_client] do
        logger.info("################################################################################")
        logger.info("# CHEF-CLIENT START")
        logger.info("################################################################################")
        sudo("bash -c '([[ -f /etc/init.d/chef-client ]] && /etc/init.d/chef-client start) || ([[ -f /sbin/service ]] && /sbin/service chef-client start)'")
      end

      desc "stop chef-client"
      task :stop, :roles => [:chef_client] do
        logger.info("################################################################################")
        logger.info("# CHEF-CLIENT STOP")
        logger.info("################################################################################")
        sudo("bash -c '([[ -f /etc/init.d/chef-client ]] && /etc/init.d/chef-client stop) || ([[ -f /sbin/service ]] && /sbin/service chef-client stop)'")
      end

      desc "restart chef-client"
      task :restart, :roles => [:chef_client] do
        logger.info("################################################################################")
        logger.info("# CHEF-CLIENT RESTART")
        logger.info("################################################################################")
        sudo("bash -c '([[ -f /etc/init.d/chef-client ]] && /etc/init.d/chef-client restart) || ([[ -f /sbin/service ]] && /sbin/service chef-client restart)'")
      end

      desc "reload chef-client"
      task :reload, :roles => [:chef_client] do
        logger.info("################################################################################")
        logger.info("# CHEF-CLIENT RELOAD")
        logger.info("################################################################################")
        sudo("bash -c '([[ -f /etc/init.d/chef-client ]] && /etc/init.d/chef-client reload) || ([[ -f /sbin/service ]] && /sbin/service chef-client reload)'")
      end

      desc "chef-client status"
      task :status, :roles => [:chef_client] do
        logger.info("################################################################################")
        logger.info("# CHEF-CLIENT STATUS")
        logger.info("################################################################################")
        sudo("bash -c '([[ -f /etc/init.d/chef-client ]] && /etc/init.d/chef-client status) || ([[ -f /sbin/service ]] && /sbin/service chef-client status)'")
      end

      desc "chef-client status"
      task :version, :roles => [:chef_client] do
        logger.info("################################################################################")
        logger.info("# CHEF-CLIENT VERSION")
        logger.info("################################################################################")
        sudo("bash -c '([[ -f /usr/bin/chef-client ]] && /usr/bin/chef-client -v) || echo \"Failed to find the chef-client executable!\"'")
      end

      desc "chef-client bootstrap; runs chef-client once via command line"
      task :bootstrap, :roles => [:chef_client] do
        logger.info("################################################################################")
        logger.info("# CHEF-CLIENT BOOTSTRAP")
        logger.info("################################################################################")
        sudo("bash -c '([[ -f /usr/bin/chef-client ]] && /usr/bin/chef-client) || echo \"Failed to find the chef-client executable!\"'")
      end

    end
  end

end
