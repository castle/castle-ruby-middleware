# frozen_string_literal: true

module Castle
  class Middleware
    class Sensor
      extend Forwardable
      def_delegators :@middleware, :log, :configuration

      attr_reader :app

      JS_IS_INJECTED_KEY = 'castle.injected'
      CJS_PATH = 'https://d2t77mnxyo7adj.cloudfront.net/v1/c.js'

      def initialize(app)
        @app = app
        @middleware = Middleware.instance
      end

      def call(env)
        app_result = app.call(env)

        begin
          return app_result unless add_js?(env, app_result[0], app_result[1])

          response_string = add_js(env, app_result[2])

          build_response(env, app_result, response_string)
        rescue StandardError => e
          log(:debug, "[Castle] castle.js could not be added because #{e} exception")
          app_result
        end
      end

      def add_js?(env, status, headers)
        status == 200 && !env[JS_IS_INJECTED_KEY] &&
          html?(headers) && !attachment?(headers) && !streaming?(headers)
      end

      def html?(headers)
        headers['Content-Type']&.include?('text/html')
      end

      def attachment?(headers)
        headers['Content-Disposition'].to_s.include?('attachment')
      end

      def streaming?(headers)
        headers['Transfer-Encoding'].to_s == 'chunked'
      end

      def add_js(env, response)
        body = join_body(response)
        close_old_response(response)

        head_open_end = find_end_of_head_open(body)
        return nil unless head_open_end

        build_body_with_js(env, body, head_open_end)
      rescue StandardError => e
        log(:error, "[Castle] castle.js could not be added because #{e} exception")
        nil
      end

      def build_response(env, app_result, response_string)
        return app_result unless response_string

        env[JS_IS_INJECTED_KEY] = true
        response = ::Rack::Response.new(response_string, app_result[0],
                                        app_result[1])

        response.finish
      end

      def build_body_with_js(env, body, head_open_end)
        return body unless head_open_end

        [
          body[0..head_open_end],
          complete_js_content(env),
          body[head_open_end + 1..-1]
        ].join
      end

      def find_end_of_head_open(body)
        head_open = body.index(/<head\W/)
        body.index('>', head_open) if head_open
      end

      def join_body(response)
        response.to_a.map(&:to_s).join
      end

      def close_old_response(response)
        response.close if response.respond_to?(:close)
      end

      def complete_js_content(env)
        [
          "\n",
          script_tag('', type: 'text/javascript', src: "#{CJS_PATH}?#{configuration.app_id}"),
          script_tag(js_commands(env).join, js_options(env)),
          "\n"
        ].join
      end

      def js_commands(env)
        [
          "\n",
          tracker_url_command,
          identify_command(env),
          secure_command(env),
          "\n"
        ].compact
      end

      def js_options(env)
        options = { type: 'text/javascript' }
        if configuration.security_headers
          nonce = SecurityHeaders.call(env)
          options[:nonce] = nonce unless nonce.nil?
        end
        options
      end

      def tracker_url_command
        return unless configuration.tracker_url

        "_castle('setTrackerUrl', '#{configuration.tracker_url}');"
      end

      def identify_command(env)
        return unless env['castle'].user_id

        "_castle('identify', '#{env['castle'].user_id}');"
      end

      def secure_command(env)
        return unless env['castle'].user_id

        hmac = OpenSSL::HMAC.hexdigest(
          'sha256',
          configuration.api_secret,
          env['castle'].user_id.to_s
        )
        "_castle('secure', '#{hmac}');"
      end

      def script_tag(content, options)
        options_to_attrs = options.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
        script_tag_content = "<script #{options_to_attrs}>#{content}</script>"
        html_safe_if_needed(script_tag_content)
      end

      def html_safe_if_needed(string)
        string = string.html_safe if string.respond_to?(:html_safe)
        string
      end
    end
  end
end
