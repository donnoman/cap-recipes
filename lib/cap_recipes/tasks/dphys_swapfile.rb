Dir[File.join(File.dirname(__FILE__), 'dphys_swapfile/*.rb')].sort.each { |lib| require lib }
