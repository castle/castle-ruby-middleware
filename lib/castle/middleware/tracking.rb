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

        resource = prefetch_resource_if_needed(req)

        # preserve state of path
        path = req.path

        # [status, headers, body]
        app_result = app.call(env)

        # Find a matching track event from the config
        mappings = @event_mapping.find_by_rack_request(app_result[0].to_s, path, app_result[1], req, false)

        mappings.each do |mapping|
          resource ||= configuration.services.provide_user.call(req, true)

          # get event properties from params
          event_properties = PropertiesProvide.call(req.params, mapping.properties)

          # get user_traits_from_params from params
          user_traits_from_params = PropertiesProvide.call(req.params, mapping.user_traits_from_params)

          # Send track request as configured
          process_track(req, resource, mapping, user_traits_from_params, event_properties)
        end

        app_result
      end

      private

      def prefetch_resource_if_needed(req)
        early_mapping = @event_mapping.find_by_rack_request(nil, req.path, nil, req, false).detect(&:quitting)

        configuration.services.provide_user.call(req, true) if early_mapping
      end

      # generate track call
      def process_track(req, resource, mapping, user_traits_from_params, properties)
        configuration.services.transport.call(
          ::Castle::Client.to_context(req),
          ::Castle::Client.to_options(
            user_id: Identification.id(resource, configuration.identify),
            user_traits: Identification.traits(
              resource, configuration.user_traits
            ).merge(user_traits_from_params),
            event: mapping.event,
            properties: properties
          )
        )
      end
    end
  end
end
