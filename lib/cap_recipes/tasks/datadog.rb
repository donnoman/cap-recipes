Dir[File.join(File.dirname(__FILE__), 'datadog/*.rb')].sort.each { |lib| require lib }
