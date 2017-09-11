
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
          event_name = "[#{app_result[0]}] #{req.request_method} #{req.path}"

          if app_result[1]['Location']
            event_name += ' > ' + URI(app_result[1]['Location']).path
          end

          # Extract headers from request into a string
          headers = ::Castle::Extractors::Headers.new(req).call

          # Read client ID from cookies
          client_id = ::Castle::Extractors::ClientId.new(req).call(app_result, '__cid')

          # Send request as configured
          Middleware.configuration.transport.({
            user_id: env['castle'].user_id,
            traits: env['castle'].traits,
            name: event_name,
            properties: req.params
          }, {
            headers: headers,
            client_id: client_id,
            ip: req.ip
          })
        end

        app_result
      end
    end
  end
end
