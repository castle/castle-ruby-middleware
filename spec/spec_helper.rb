# frozen_string_literal: true

require 'bundler/setup'
require 'byebug'

require 'coveralls'
Coveralls.wear!

require 'castle/middleware'

RSpec.configure do |config|
  config.before(:each) do
    ::Castle::Middleware.configuration.reset!
    ::Castle::Middleware.configure {}
  end
end
