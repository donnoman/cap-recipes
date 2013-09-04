Dir[File.join(File.dirname(__FILE__), 'hosts/*.rb')].sort.each { |lib| require lib }
