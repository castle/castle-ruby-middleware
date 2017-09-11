
# frozen_string_literal: true

module Castle
  module Middleware
    class RequestConfig
      attr_reader :user_id
      attr_reader :traits

      def identify(user_id, traits)
        @user_id = user_id
        @traits = traits
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

        app_result = app.call(env)

        if req.post? || req.put? || req.delete?
          event_name = build_event_name(req, app_result)

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
              properties: req.params
            },
            {
              headers: headers,
              client_id: client_id,
              ip: req.ip
            }
          )
        end

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
