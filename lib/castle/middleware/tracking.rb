
# frozen_string_literal: true

module Castle
  module Middleware
    class RequestConfig
      attr_reader :user_id
      attr_reader :traits
      attr_reader :props

      def identify(user_id, traits)
        @user_id = user_id
        @traits = traits
      end

      def properties(props)
        @props = props
      end
    end

    class Tracking
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        env['castle'] = RequestConfig.new

        req = Rack::Request.new(env)

        # [status, headers, body]
        app_result = app.call(env)

        # Find a matching event from the config
        mapping = Middleware.event_mapping.find_by_rack_request(app_result, req)

        return app_result if mapping.nil?

        # event_name = build_event_name(req, app_result)
        event_name = mapping.event
        properties = mapping.properties

        flat_params = Middleware::ParamsFlattener.(req.params)

        event_properties = properties.each_with_object({}) do |(property, param), hash|
          hash[property] = flat_params[param]
        end

        # Convert password to a boolean
        # TODO: Check agains list of known password field names
        event_properties[:password] = !event_properties[:password].to_s.empty?

        # Extract headers from request into a string
        headers = ::Castle::Extractors::Headers.new(req).call

        # Read client ID from cookies
        client_id = ::Castle::Extractors::ClientId.new(req).call(app_result, '__cid')

        # Send request as configured
        Middleware.configuration.transport.(
          {
            user_id: env['castle'].user_id,
            traits: env['castle'].traits,
            name: event_name,
            properties: (env['castle'].props || {}).merge(event_properties)
          },
          {
            headers: headers,
            client_id: client_id,
            ip: req.ip
          }
        )

        app_result
      end

      def build_event_name(request, response)
        event_name = "[#{response[0]}] #{request.request_method} #{request.path}"
        if response[1]['Location']
          event_name += ' > ' + URI(response[1]['Location']).path
        end

        event_name
      end
    end
  end
end
