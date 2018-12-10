# frozen_string_literal: true

module Castle
  class Middleware
    # validates config options
    class Configuration
      class Validate
        def call(options)
          validate_api_secret(options)
          validate_app_id(options)
          error(:events) unless options.events.is_a?(Hash)
          error(:identify) unless options.identify.is_a?(Hash)
          error(:'identify/id') unless options.identify['id'].nil?
          error(:'identify/created_at') unless options.identify['created_at'].nil?
        end

        private

        def error(name)
          raise Castle::Middleware::ConfigError, "[Castle] wrong config `#{name}` value"
        end

        def validate_api_secret(options)
          error(:api_secret) if !options.api_secret.is_a?(String) || options.api_secret.empty?
        end

        def validate_app_id(options)
          error(:app_id) if !options.app_id.is_a?(String) || options.app_id.empty?
        end
      end
    end
  end
end
