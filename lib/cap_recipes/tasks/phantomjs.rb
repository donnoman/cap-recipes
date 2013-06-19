Dir[File.join(File.dirname(__FILE__), 'phantomjs/*.rb')].sort.each { |lib| require lib }
