# frozen_string_literal: true

require 'castle/middleware/request_config'
require 'castle/middleware/event_mapper'
require 'castle/middleware/params_flattener'

module Castle
  class Middleware
    class Authenticating
      extend Forwardable
      def_delegators :@middleware, :log, :configuration, :authenticate, :track

      attr_reader :app

      def initialize(app)
        @app = app
        @middleware = Middleware.instance
        @mapper = Castle::Middleware::EventMapper.build('$login.succeeded' => configuration.login_event)
      end

      def call(env)
        env['castle'] = RequestConfig.new
        req = Rack::Request.new(env)
        login_req = login?(req)

        resource = generate_resource(req.params, env) if login_req

        # [status, headers, body]
        app_result = app.call(env)

        if login_req
          if login_success?(app_result, req)
            redirect_result = authentication_verdict(resource, req, env)
            return [301, { 'Location' => redirect_result }, []] if redirect_result
          else
            track_login_failed(req, env)
            env['castle'].clear
          end
          app_result
        else
          env['castle'].identify(req.session['castle_user_id'], {}) if req.session['castle_user_id']
          app_result
        end
      end

      private

      def generate_resource(params, env)
        key = configuration.login_event.dig('authentication', 'key')
        key_value = ParamsFlattener.call(params)[key]
        traits = {}

        resource = configuration.services.provide_by_login_key.call(key_value)
        traits[configuration.login_event.dig('authentication', 'name')] = key_value

        env['castle'].identify(
          resource&.public_send(configuration.login_event['user_id_method']),
          traits
        )

        resource
      end

      def authentication_verdict(resource, req, env)
        return if resource.nil?

        verdict = authenticate_login_succeeded(req, env)

        case verdict[:action]
        when 'allow'
          req.session['castle_user_id'] = env['castle'].user_id
          nil
        when 'challenge'
          redirect_result = configuration.services.challenge.call(req, resource)
          configuration.services.logout.call(req, env)
          redirect_result
        when 'deny'
          redirect_result = configuration.services.deny.call(req, resource)
          configuration.services.logout.call(req, env)
          redirect_result
        end
      end

      def authenticate_login_succeeded(req, env)
        authenticate(
          Castle::Client.to_context(req),
          Castle::Client.to_options(
            user_id: env['castle'].user_id,
            event: '$login.succeeded'
          )
        )
      end

      def track_login_failed(req, env)
        track(
          ::Castle::Client.to_context(req),
          ::Castle::Client.to_options(
            user_id: env['castle'].user_id,
            event: '$login.failed'
          )
        )
      end

      def login?(req)
        mapping = @mapper.find_by_prerack_request(req)
        !mapping.nil?
      end

      def login_success?(app_result, req)
        mapping = @mapper.find_by_rack_request(app_result, req)
        !mapping.nil?
      end
    end
  end
end
