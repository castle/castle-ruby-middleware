# frozen_string_literal: true

module Castle
  class Middleware
    # validates config options
    class Configuration
      class Validate
        def call(options)
          error(:api_secret) if !options.api_secret.is_a?(String) || options.api_secret.empty?
          error(:app_id) if !options.app_id.is_a?(String) || options.app_id.empty?
          error(:events) unless options.events.is_a?(Hash)
          error(:identify) unless options.identify.is_a?(Hash)
        end

        private

        def error(name)
          raise Castle::Middleware::ConfigError, "[Castle] wrong config `#{name}` value"
        end
      end
    end
  end
end
