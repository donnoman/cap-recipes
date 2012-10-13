Dir[File.join(File.dirname(__FILE__), 'chef_client/*.rb')].sort.each { |lib| require lib }
