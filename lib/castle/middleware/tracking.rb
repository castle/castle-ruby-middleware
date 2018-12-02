# frozen_string_literal: true

require 'castle/middleware/event_mapper'
require 'castle/middleware/properties_provide'
require 'castle/middleware/identification'

module Castle
  class Middleware
    class Tracking
      extend Forwardable
      def_delegators :@middleware, :log, :configuration

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

        # Find a matching track event from the config
        mapping = @event_mapping.find_by_rack_request(app_result, req, false)

        return app_result if mapping.nil?

        resource = configuration.services.provide_user.call(req)

        return app_result if resource.nil?

        # get event properties from params
        event_properties = PropertiesProvide.call(req.params, mapping.properties)

        # Send track request as configured
        process_track(req, resource, mapping, event_properties)

        app_result
      end

      private

      # generate track call
      def process_track(req, resource, mapping, properties)
        configuration.services.transport.call(
          ::Castle::Client.to_context(req),
          ::Castle::Client.to_options(
            user_id: Identification.id(resource, configuration.identify),
            user_traits: Identification.traits(resource, configuration.identify),
            event: mapping.event,
            properties: properties
          )
        )
      end
    end
  end
end
