Dir[File.join(File.dirname(__FILE__), 'java_7_oracle/*.rb')].sort.each { |lib| require lib }
