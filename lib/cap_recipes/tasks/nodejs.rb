Dir[File.join(File.dirname(__FILE__), 'nodejs/*.rb')].sort.each { |lib| require lib }
