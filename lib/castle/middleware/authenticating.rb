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

        # preserve state of path
        path = req.path

        # [status, headers, body]
        app_result = app.call(env)
        status, headers = app_result
        return app_result if app_result.nil?

        # Find a matching event from the config
        mapping = @event_mapping.find_by_rack_request(status.to_s, path, headers, req, true).first

        return app_result if mapping.nil?

        resource = configuration.services.provide_user.call(req, true)

        return app_result if resource.nil?

        # get event properties from params
        event_properties = PropertiesProvide.call(req.params, mapping.properties)

        # get user_traits from params
        user_traits_from_params = PropertiesProvide.call(req.params, mapping.user_traits_from_params)

        verdict = process_authenticate(req, resource, mapping, user_traits_from_params, event_properties)

        if mapping.challenge
          redirect_result = authentication_verdict(verdict, req, resource)
          if redirect_result
            return [302, {
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

      def process_authenticate(req, resource, mapping, user_traits_from_params, event_properties)
        authenticate(
          ::Castle::Payload::Prepare.call(
            {
              user_id: Identification.id(resource, configuration.identify),
              user_traits: Identification.traits(
                resource, configuration.user_traits
              ).merge(user_traits_from_params),
              event: mapping.event,
              properties: event_properties
            },
            req
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
