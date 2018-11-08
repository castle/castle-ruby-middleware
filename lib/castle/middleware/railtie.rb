# frozen_string_literal: true

require 'rails/railtie'

module Castle
  class Middleware
    class Railtie < ::Rails::Railtie
      initializer 'castle.middleware.rails' do |app|
        app.config.middleware.insert_after ActionDispatch::Flash,
                                           Castle::Middleware::Sensor
        app.config.middleware.insert_after ActionDispatch::Flash,
                                           Castle::Middleware::Tracking
        app.config.middleware.insert_after ActionDispatch::Flash,
                                           Castle::Middleware::Authenticating
      end
    end
  end
end
