require File.expand_path(File.dirname(__FILE__) + '/../utilities')
Capistrano::Configuration.instance(true).load do
  namespace :hosts do
    roles[:hosts]
    set :hosts_entries, {}
    set :hosts_file_dest, "/etc/hosts"

    #the identifier here is used to locate the correct line in case the ip or name change so it can be removed.
    def add(identifier,ip,name)
      hosts_entries[identifier] = {:ip => ip, :name => name}
    end

    desc "Install custom host entries"
    task :install do
      # meet expectations to have an install task.
      setup
    end

    desc "setup hosts entries"
    task :setup, :roles => :hosts do
      run "#{sudo} [ ! -f /etc/hosts.orig ] && #{sudo} cp /etc/hosts /etc/hosts.orig; true"
      run "#{sudo} rm -rf /tmp/hosts.new"
      hosts_entries.each do |identifier,value|
        run "#{sudo} grep -v '##{identifier}' #{hosts_file_dest} > /tmp/hosts.new"
        run %Q{#{sudo} sh -c 'echo "#{value[:ip]}    #{value[:name]} ##{identifier}" >> /tmp/hosts.new'}
      end
      run "#{sudo} chown root:root /tmp/hosts.new && #{sudo} mv /tmp/hosts.new #{hosts_file_dest}"
    end

  end
end
