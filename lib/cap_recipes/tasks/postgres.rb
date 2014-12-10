Dir[File.join(File.dirname(__FILE__), 'postgres/*.rb')].sort.each { |lib| require lib }
