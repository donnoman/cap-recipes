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
        run("([[ -f /etc/init.d/chef-client ]] && #{sudo} /etc/init.d/chef-client start) || ([[ -f /sbin/service ]] && #{sudo} /sbin/service chef-client start)")
      end

      desc "stop chef-client"
      task :stop, :roles => [:chef_client] do
        logger.info("################################################################################")
        logger.info("# CHEF-CLIENT STOP")
        logger.info("################################################################################")
        run("([[ -f /etc/init.d/chef-client ]] && #{sudo} /etc/init.d/chef-client stop) || ([[ -f /sbin/service ]] && #{sudo} /sbin/service chef-client stop)")
      end

      desc "restart chef-client"
      task :restart, :roles => [:chef_client] do
        logger.info("################################################################################")
        logger.info("# CHEF-CLIENT RESTART")
        logger.info("################################################################################")
        run("([[ -f /etc/init.d/chef-client ]] && #{sudo} /etc/init.d/chef-client restart) || ([[ -f /sbin/service ]] && #{sudo} /sbin/service chef-client restart)")
      end

      desc "reload chef-client"
      task :reload, :roles => [:chef_client] do
        logger.info("################################################################################")
        logger.info("# CHEF-CLIENT RELOAD")
        logger.info("################################################################################")
        run("([[ -f /etc/init.d/chef-client ]] && #{sudo} /etc/init.d/chef-client reload) || ([[ -f /sbin/service ]] && #{sudo} /sbin/service chef-client reload)")
      end

      desc "chef-client status"
      task :status, :roles => [:chef_client] do
        logger.info("################################################################################")
        logger.info("# CHEF-CLIENT STATUS")
        logger.info("################################################################################")
        run("([[ -f /etc/init.d/chef-client ]] && #{sudo} /etc/init.d/chef-client status) || ([[ -f /sbin/service ]] && #{sudo} /sbin/service chef-client status)")
      end

    end
  end

end
