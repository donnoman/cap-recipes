Dir[File.join(File.dirname(__FILE__), 'stingray/*.rb')].sort.each { |lib| require lib }
