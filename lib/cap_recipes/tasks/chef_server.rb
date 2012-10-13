Dir[File.join(File.dirname(__FILE__), 'chef_server/*.rb')].sort.each { |lib| require lib }
