# frozen_string_literal: true

module Castle
  module Middleware
    class Sensor
      attr_reader :app
      attr_reader :config

      JS_IS_INJECTED_KEY = 'castle.js_is_injected'
      SNIPPET = File.read(File.expand_path('../../../../data/castle.snippet.js', __FILE__))

      def initialize(app)
        @app = app
        @config = config
        @script_commands = {}
      end

      def call(env)
        app_result = app.call(env)

        begin
          return app_result unless add_js?(env, app_result[0], app_result[1])

          response_string = add_js(env, app_result[2])

          build_response(env, app_result, response_string)
        rescue => e
          log(:debug, "[Castle] castle.js could not be added because #{e} exception")
          app_result
        end
      end

      def log(level, message)
        return unless Middleware.configuration.logger
        Middleware.configuration.logger.send(level.to_s, message)
      end

      def add_js?(env, status, headers)
        status == 200 && !env[JS_IS_INJECTED_KEY] &&
          html?(headers) && !attachment?(headers) && !streaming?(env)
      end

      def html?(headers)
        headers['Content-Type'] && headers['Content-Type'].include?('text/html')
      end

      def attachment?(headers)
        headers['Content-Disposition'].to_s.include?('attachment')
      end

      def streaming?(env)
        return false unless defined?(ActionController::Live)

        env['action_controller.instance'].class.included_modules.include?(ActionController::Live)
      end

      def add_js(env, response)
        body = join_body(response)
        close_old_response(response)

        return nil unless body

        head_open_end = find_end_of_head_open(body)
        return nil unless head_open_end

        build_body_with_js(env, body, head_open_end)
      rescue => e
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
        app_id!(env)
        identify!(env)
        secure!(env)

        commands = ["\n", @script_commands.values.join, "\n"].join

        snippet_js_tag(env) + script_tag(commands, env)
      end

      def app_id!(_)
        @script_commands[:app_id] =
          "_castle('setAppId', '#{Castle::Middleware.configuration.app_id}');"
      end

      def identify!(env)
        return unless env['castle'].user_id
        @script_commands[:identify] = "_castle('identify', '#{env['castle'].user_id}');"
      end

      def secure!(env)
        return unless env['castle'].user_id
        hmac = OpenSSL::HMAC.hexdigest(
          'sha256',
          Castle::Middleware.configuration.api_secret,
          env['castle'].user_id.to_s
        )
        @script_commands[:secure] = "_castle('secure', '#{hmac}');"
      end

      def add_person_data(js_config, env)
        person_data = extract_person_data_from_controller(env)

        return if person_data && person_data.empty?

        js_config[:payload] ||= {}
        js_config[:payload][:person] = person_data if person_data
      end

      def snippet_js_tag(env)
        script_tag(js_snippet, env)
      end

      def js_snippet
        SNIPPET
      end

      def script_tag(content, env)
        if append_nonce?
          nonce = ::SecureHeaders.content_security_policy_script_nonce(::Rack::Request.new(env))
          script_tag_content = "\n<script type=\"text/javascript\" nonce=\"#{nonce}\">#{content}</script>"
        else
          script_tag_content = "\n<script type=\"text/javascript\">#{content}</script>"
        end

        html_safe_if_needed(script_tag_content)
      end

      def html_safe_if_needed(string)
        string = string.html_safe if string.respond_to?(:html_safe)
        string
      end

      def append_nonce?
        defined?(::SecureHeaders) && ::SecureHeaders.respond_to?(:content_security_policy_script_nonce) &&
          defined?(::SecureHeaders::Configuration) &&
          !::SecureHeaders::Configuration.get.csp.opt_out? &&
          !::SecureHeaders::Configuration.get.current_csp[:script_src].to_a.include?("'unsafe-inline'")
      end
    end
  end
end
