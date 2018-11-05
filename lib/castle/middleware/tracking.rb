# frozen_string_literal: true

require 'castle/middleware/request_config'

module Castle
  class Middleware
    class Tracking
      extend Forwardable
      def_delegators :@middleware, :log, :configuration, :event_mapping

      attr_reader :app

      def initialize(app)
        @app = app
        @middleware = Middleware.instance
      end

      def call(env)
        env['castle'] = RequestConfig.new
        req = Rack::Request.new(env)

        # [status, headers, body]
        app_result = app.call(env)

        # Find a matching event from the config
        mapping = event_mapping.find_by_rack_request(app_result, req)

        return app_result if mapping.nil?

        event_properties = collect_event_properties(
          req.params, mapping.properties
        ).merge(env['castle'].props || {})

        # Send track request as configured
        track(req, env, mapping, event_properties)

        app_result
      end

      def collect_event_properties(request_params, properties_map)
        flat_params = ParamsFlattener.call(request_params)

        event_properties = properties_map.each_with_object({}) do |(property, param), hash|
          hash[property] = flat_params[param]
        end

        # Convert password to a boolean
        # TODO: Check agains list of known password field names
        if event_properties.key?(:password)
          event_properties[:password] = !event_properties[:password].to_s.empty?
        end

        event_properties
      end

      private

      def track(req, env, mapping, event_properties)
        configuration.transport.call(
          ::Castle::Client.to_context(req),
          ::Castle::Client.to_options(
            user_id: env['castle'].user_id,
            user_traits: env['castle'].traits,
            event: mapping.event,
            properties: event_properties
          )
        )
      end
    end
  end
end
