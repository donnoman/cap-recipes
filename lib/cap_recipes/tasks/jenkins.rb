Dir[File.join(File.dirname(__FILE__), 'jenkins/*.rb')].sort.each { |lib| require lib }
