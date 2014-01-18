Capistrano::Configuration.instance(true).load do
  before "deploy:provision", "ruby19:install"
  before "ruby19:install", "aptitude:updates"
  after "ruby19:install", "ruby19:rubygems_source_fix"
  after "ruby19:install", "ruby19:ruby_debugger"
end
