Dir[File.join(File.dirname(__FILE__), 'geoip/*.rb')].sort.each { |lib| require lib }
