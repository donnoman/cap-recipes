Dir[File.join(File.dirname(__FILE__), 'denyhosts/*.rb')].sort.each { |lib| require lib }
