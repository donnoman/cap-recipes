Dir[File.join(File.dirname(__FILE__), 'ree/*.rb')].sort.each { |lib| require lib }