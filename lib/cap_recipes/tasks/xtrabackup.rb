Dir[File.join(File.dirname(__FILE__), 'xtrabackup/*.rb')].sort.each { |lib| require lib }