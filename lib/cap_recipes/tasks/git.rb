Dir[File.join(File.dirname(__FILE__), 'git/*.rb')].sort.each { |lib| require lib }
