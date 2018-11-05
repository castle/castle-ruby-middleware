# frozen_string_literal: true

require 'bundler/setup'
require 'byebug'

require 'coveralls'
Coveralls.wear!

require 'castle/middleware'

RSpec.configure do |config|
  config.before(:each) do
    ::Castle::Middleware.configure do |c|
      c.api_secret = 'secret'
      c.file_path = "./spec/castle/middleware/castle_config.yml"
    end
  end
end
