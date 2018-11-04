# frozen_string_literal: true

module Castle
  module Middleware
    class Sensor
      attr_reader :app
      attr_reader :config

      JS_IS_INJECTED_KEY = 'castle.injected'.freeze
      CJS_PATH = 'https://d2t77mnxyo7adj.cloudfront.net/v1/c.js'.freeze

      def initialize(app)
        @app = app
        @config = config
      end

      def call(env)
        app_result = app.call(env)
        byebug

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
        Middleware.log(level, message)
      end

      def add_js?(env, status, headers)
        status == 200 && !env[JS_IS_INJECTED_KEY] &&
          html?(headers) && !attachment?(headers) && !streaming?(headers)
      end

      def html?(headers)
        headers['Content-Type'] && headers['Content-Type'].include?('text/html')
      end

      def attachment?(headers)
        headers['Content-Disposition'].to_s.include?('attachment')
      end

      def streaming?(env)
        headers['Transfer-Encoding'].to_s == 'chunked'
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
        commands = [
          "\n",
          identify_command(env),
          secure_command(env),
          "\n"
        ].compact.join

        snippet_cjs_tag + script_tag(commands, env)
      end

      def identify_command(env)
        return unless env['castle'].user_id
        "_castle('identify', '#{env['castle'].user_id}');"
      end

      def secure_command(env)
        return unless env['castle'].user_id
        hmac = OpenSSL::HMAC.hexdigest(
          'sha256',
          Castle::Middleware.configuration.api_secret,
          env['castle'].user_id.to_s
        )
        "_castle('secure', '#{hmac}');"
      end

      def snippet_cjs_tag
        "<script type=\"text/javascript\" src=\"#{CJS_PATH}?#{Castle::Middleware.configuration.app_id}\"></script>"
      end

      def script_tag(content, env)
        script_tag_content = "\n<script type=\"text/javascript\">#{content}</script>"
        html_safe_if_needed(script_tag_content)
      end

      def html_safe_if_needed(string)
        string = string.html_safe if string.respond_to?(:html_safe)
        string
      end
    end
  end
end
