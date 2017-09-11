# frozen_string_literal: true

require 'rails/railtie'

module Castle
  module Middleware
    class Railtie < ::Rails::Railtie
      initializer 'rollbar.middleware.rails' do |app|
        # TODO(wallin): Flash middleware might not exist. Look for common
        # Rack Middlewares instead?
        # https://github.com/rails/rails/blob/ac3564693c6df9c9f9a46f681f4f6a4ea84997e6/guides/source/rails_on_rack.md#internal-middleware-stack
        if Middleware.configuration.auto_insert_middleware
          app.config.middleware.insert_after ActionDispatch::Flash,
                                             Castle::Middleware::Tracking
          app.config.middleware.insert_after ActionDispatch::Flash,
                                             Castle::Middleware::Sensor
        end
      end
    end
  end
end
