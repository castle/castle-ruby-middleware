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
        req = Rack::Request.new(env)

        # [status, headers, body]
        app_result = app.call(env)

        # Find a matching event from the config
        mapping = @event_mapping.find_by_rack_request(app_result, req, true)

        return app_result if mapping.nil?

        resource = configuration.services.provide_user.call(req)

        return app_result if resource.nil?

        # get event properties from params
        event_properties = PropertiesProvide.call(req.params, mapping.properties)

        verdict = process_authenticate(req, resource, mapping, event_properties)

        if mapping.challenge
          redirect_result = authentication_verdict(verdict, req, resource)
          return [301, { 'Location' => redirect_result }, []] if redirect_result
        end

        app_result
      end

      private

      def authentication_verdict(verdict, req, resource)
        case verdict[:action]
        when 'challenge'
          return unless configuration.services.challenge

          redirect_result = configuration.services.challenge.call(req, resource)
          configuration.services.logout.call(req)
          redirect_result
        when 'deny'
          return unless configuration.services.deny

          redirect_result = configuration.services.deny.call(req, resource)
          configuration.services.logout.call(req)
          redirect_result
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
    end
  end
end
