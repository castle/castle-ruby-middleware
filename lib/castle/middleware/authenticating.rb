# frozen_string_literal: true

require 'castle/middleware/request_config'

module Castle
  class Middleware
    class Authenticating
      extend Forwardable
      def_delegators :@middleware, :log, :configuration, :event_mapping, :authenticate, :track

      attr_reader :app

      def initialize(app)
        @app = app
        @middleware = Middleware.instance
      end

      def call(env)
        env['castle'] = RequestConfig.new
        req = Rack::Request.new(env)

        resource = generate_resource if login?(req)

        # [status, headers, body]
        app_result = app.call(env)

        if login?(req)
          if login_success?(app_result)
            redirect_result = authentication_verdict(resource, req, env)
            return [301, { 'Location' => redirect_result }, []] if redirect_result
          else
            track_login_failed(req, env)
          end
          app_result
        else
          env['castle'].identify(nil, req.session['castle_user_id'], {}) if req.session['castle_user_id']
          app_result
        end
      end

      private

      def init_resource
        key = ParamsFlattener.call(req.params)[configuration.authentication['key']]
        traits = {}

        resource = configuration.services.provide_by_login_key.call(key)
        traits[configuration.authentication['key']] = key

        env['castle'].identify(
          resource&.public_send(configuration.user_id_method),
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
          redirect_result = configuration.challenge.call(req, resource)
          configuration.logout.call(req, env)
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

      def track_login_failed(req, env, _mapping, _event_properties)
        track.call(
          ::Castle::Client.to_context(req),
          ::Castle::Client.to_options(
            user_id: env['castle'].user_id,
            event: '$login.failed'
          )
        )
      end

      def login?(req)
        req.path == configuration.login_event['path'] && req.request_method == configuration.login_event['method'] && req.form_data?
      end

      def login_success?(app_result)
        app_result[0] = configuration.login_event['success_status']
      end
    end
  end
end
