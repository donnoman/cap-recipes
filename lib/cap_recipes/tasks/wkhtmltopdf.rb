Dir[File.join(File.dirname(__FILE__), 'wkhtmltopdf/*.rb')].sort.each { |lib| require lib }
