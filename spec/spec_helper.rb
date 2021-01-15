# frozen_string_literal: true

require 'bundler/setup'
require 'byebug'

require 'coveralls'
Coveralls.wear!

require 'castle/middleware'

RSpec.configure do |config|
  config.before do
    ::Castle::Middleware.configure do |c|
      c.api_secret = 'secret'
      c.api_options = { url: 'https://api.castle.local:3000' }
      c.app_id = '1234'
      c.file_path = './spec/castle/middleware/castle_config.yml'
    end
  end
end
