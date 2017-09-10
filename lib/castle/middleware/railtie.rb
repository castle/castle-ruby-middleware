require 'rails/railtie'

module Castle
  module Middleware
    class Railtie < ::Rails::Railtie
      initializer 'rollbar.middleware.rails' do |app|
        app.config.middleware.insert_after ActionDispatch::Flash,
                                           Castle::Middleware::Tracking
        app.config.middleware.insert_after ActionDispatch::Flash,
                                           Castle::Middleware::Sensor
      end
    end
  end
end
