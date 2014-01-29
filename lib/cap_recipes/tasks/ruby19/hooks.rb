Capistrano::Configuration.instance(true).load do
  after "deploy:provision", "ruby19:install"
  after "ruby19:install", "ruby19:rubygems_source_fix"
  after "ruby19:install", "ruby19:ruby_debugger"
end
