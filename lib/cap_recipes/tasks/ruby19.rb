puts "WARNING: ruby19 has been removed require 'cap_recipes/tasks/ruby' instead."
Dir[File.join(File.dirname(__FILE__), 'ruby/*.rb')].sort.each { |lib| require lib }
