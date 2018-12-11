# frozen_string_literal: true

require 'castle/middleware/identification'
require 'castle/middleware/event_mapper'
require 'castle/middleware/properties_provide'

module Castle
  class Middleware
    class Authenticating
      extend Forwardable
      def_delegators :@middleware, :log, :configuration, :authenticate

      attr_reader :app

      def initialize(app)
        @app = app
        @middleware = Middleware.instance
        @event_mapping = Castle::Middleware::EventMapper.build(configuration.events)
      end

      def call(env)
        # [status, headers, body]
        app_result = app.call(env)

        req = Rack::Request.new(env)

        # Find a matching event from the config
        mapping = @event_mapping.find_by_rack_request(app_result[0].to_s, app_result[1], req, true).first

        return app_result if mapping.nil?

        resource = configuration.services.provide_user.call(req, true)

        return app_result if resource.nil?

        # get event properties from params
        event_properties = PropertiesProvide.call(req.params, mapping.properties)

        verdict = process_authenticate(req, resource, mapping, event_properties)

        if mapping.challenge
          redirect_result = authentication_verdict(verdict, req, resource)
          if redirect_result
            return [301, {
              'Location' => redirect_result,
              'Content-Type' => 'text/html',
              'Content-Length' => '0'
            }, []]
          end
        end

        app_result
      end

      private

      def authentication_verdict(verdict, req, resource)
        case verdict[:action]
        when 'challenge' then challenge(req, resource)
        when 'deny' then deny(req, resource)
        end
      end

      def process_authenticate(req, resource, mapping, event_properties)
        authenticate(
          Castle::Client.to_context(req),
          Castle::Client.to_options(
            user_id: Identification.id(resource, configuration.identify),
            user_traits: Identification.traits(resource, configuration.identify),
            event: mapping.event,
            properties: event_properties
          )
        )
      end

      def challenge(req, resource)
        return unless configuration.services.challenge

        configuration.services.challenge.call(req, resource)
      end

      def deny(req, resource)
        return unless configuration.services.deny

        configuration.services.deny.call(req, resource)
      end
    end
  end
end
