require 'bundler/setup'
Bundler.setup

require "capistrano"

# ---- bugfix
#`exit?': undefined method `run?' for Test::Unit:Module (NoMethodError)
#can be solved with require test/unit but this will result in extra test-output
module Test
  module Unit
    def self.run?
      true
    end
  end
end

RSpec.configure do |config|
  # some (optional) config here
end

