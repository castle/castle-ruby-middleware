
# frozen_string_literal: true

def dot(object, prefix = nil)
  if object.is_a? Hash
    object.map do |key, value|
      if prefix
        dot_it value, "#{prefix}.#{key}"
      else
        dot_it value, "#{key}"
      end
    end.reduce(&:merge)
  else
    {prefix => object}
  end
end

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

        app_result = app.call(env)

        # Find a matching event from the config
        event = Middleware.configuration.events.select do |event, conditions|
          app_result[0].to_s[conditions[:status]] &&
          req.request_method[conditions[:method]] &&
          req.path[conditions[:path]]
        end

        unless event.empty?
          # event_name = build_event_name(req, app_result)
          event_name = event.keys.first.to_s
          properties = event.values.first[:properties] || {}

          flat_params = dot_it(req.params)

          event_properties = {}
          properties.each do |property, param|
            event_properties[property] = flat_params[param]
          end

          # Convert password to a boolean
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
