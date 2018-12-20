# frozen_string_literal: true

require 'castle/middleware/identification'
require 'castle/middleware/properties_provide'

module Castle
  class Middleware
    class BodyModify
      extend Forwardable
      def_delegators :@middleware, :log, :configuration

      CJS_PATH = 'https://d2t77mnxyo7adj.cloudfront.net/v1/c.js'.freeze

      def initialize
        @middleware = Middleware.instance
      end

      def call(req, response)
        old_body = join_body(response)
        close_old_response(response)

        head_open_end = find_end_of_head_open(old_body)
        return unless head_open_end

        [
          old_body[0..head_open_end],
          js_content_to_add(req),
          old_body[head_open_end + 1..-1]
        ].join
      end

      private

      def find_end_of_head_open(body)
        head_open = body.index(/<head\W/)
        body.index('>', head_open) if head_open
      end

      def join_body(response)
        body = response.respond_to?(:body) ? response.body : response
        body.to_a.map(&:to_s).join
      end

      def close_old_response(response)
        response.close if response.respond_to?(:close)
      end

      def js_content_to_add(req)
        [
          "\n",
          script_tag('', type: 'text/javascript', src: "#{CJS_PATH}?#{configuration.app_id}"),
          script_tag(js_commands(req).join, js_options(req)),
          "\n"
        ].join
      end

      def js_commands(req)
        resource = configuration.services.provide_user.call(req, false)
        [
          "\n",
          tracker_url_command,
          identify_command(resource),
          secure_command(resource),
          "\n"
        ].compact
      end

      def js_options(req)
        options = { type: 'text/javascript' }
        if configuration.security_headers
          nonce = SecurityHeaders.call(req)
          options[:nonce] = nonce unless nonce.nil?
        end
        options
      end

      def tracker_url_command
        return unless configuration.tracker_url

        "_castle('setTrackerUrl', '#{configuration.tracker_url}');"
      end

      def identify_command(resource)
        return unless resource

        "_castle('identify', '#{Identification.id(resource, configuration.identify)}');"
      end

      def secure_command(resource)
        return unless resource

        hmac = OpenSSL::HMAC.hexdigest(
          'sha256',
          configuration.api_secret,
          Identification.id(resource, configuration.identify)
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
