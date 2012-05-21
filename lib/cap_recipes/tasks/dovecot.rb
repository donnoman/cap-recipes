Dir[File.join(File.dirname(__FILE__), 'dovecot/*.rb')].sort.each { |lib| require lib }
