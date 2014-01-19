# =============================================================================
# GENERAL SETTINGS
# =============================================================================

role :web, "lb.app.com"
role :app, "demo.app.com"
role :db,  "db.app.com", :primary => true

set :application,  "demo"
set :deploy_to,  "/var/apps/#{application}"
set :deploy_via, :remote_cache
set :scm, :git
set :repository, "deploy@dev.demo.com:/home/demo.git"
set :git_enable_submodules, 1
set :keep_releases, 3
set :user, "deploy"
set :runner, "deploy"
set :password, "demo567"
set :use_sudo, true
set :branch, 'production'

ssh_options[:forward_agent] = true
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa")]
ssh_options[:paranoid] = false
default_run_options[:pty] = true

# =============================================================================
# RECIPE INCLUDES
# =============================================================================

require 'rubygems'
require 'cap_recipes/tasks/provision'
require 'cap_recipes/tasks/teelogger'
require 'cap_recipes/tasks/bundler'
require 'cap_recipes/tasks/god'
require 'cap_recipes/tasks/git'
require 'cap_recipes/tasks/ruby19'
require 'cap_recipes/tasks/nginx'
require 'cap_recipes/tasks/nginx_unicorn'
require 'cap_recipes/tasks/unicorn'
require 'cap_recipes/tasks/redis'
require 'cap_recipes/tasks/logrotate'
