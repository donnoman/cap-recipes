Dir[File.join(File.dirname(__FILE__), 'bundler/*.rb')].sort.each { |lib| require lib }