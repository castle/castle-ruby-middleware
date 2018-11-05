# frozen_string_literal: true

require 'castle/middleware/request_config'

module Castle
  class Middleware
    class Authenticating
      extend Forwardable
      def_delegators :@middleware, :log, :configuration, :event_mapping, :authenticate

      attr_reader :app

      def initialize(app)
        @app = app
        @middleware = Middleware.instance
      end

      def call(env)
        env['castle'] = RequestConfig.new
        req = Rack::Request.new(env)

        if login?(req)
          byebug
          redirect_result = authentication_verdict(req, env)
          return [301, { 'Location' => redirect_result }, []] if redirect_result
        end

        env['castle'].identify(req.session['castle_user_id'], {}) if req.session['castle_user_id']

        # [status, headers, body]
        app.call(env)
      end

      private

      def authentication_verdict(req, env)
        key = req.params.dig(*configuration.login.dig('authentication', 'key').split('.'))
        pass = req.params.dig(*configuration.login.dig('authentication', 'password').split('.'))

        resource = configuration.services.provide_by_login_key.call(key)
        return if resource.nil?

        env['castle'].identify(resource.public_send(configuration.login['user_id']), {})

        return unless configuration.services.validate_password.call(resource, pass)

        verdict = castle_authenticate(req, env)

        case verdict[:action]
        when 'allow'
          req.session['castle_user_id'] = env['castle'].user_id
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

      def castle_authenticate(req, env)
        authenticate(
          Castle::Client.to_context(req),
          Castle::Client.to_options(
            user_id: env['castle'].user_id,
            event: '$login.succeeded'
          )
        )
      end

      def login?(req)
        req.path == configuration.login['path'] && req.request_method == configuration.login['method'] && req.form_data?
      end
    end
  end
end
