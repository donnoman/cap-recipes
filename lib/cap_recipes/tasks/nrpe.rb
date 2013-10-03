Dir[File.join(File.dirname(__FILE__), 'nrpe/*.rb')].sort.each { |lib| require lib }
