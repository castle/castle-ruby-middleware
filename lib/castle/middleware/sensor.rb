# frozen_string_literal: true

require 'castle/middleware/identification'
require 'castle/middleware/properties_provide'
require 'castle/middleware/body_modify'

module Castle
  class Middleware
    class Sensor
      extend Forwardable
      def_delegators :@middleware, :log, :configuration

      attr_reader :app

      CJS_PATH = 'https://d2t77mnxyo7adj.cloudfront.net/v1/c.js'.freeze

      def initialize(app)
        @app = app
        @middleware = Middleware.instance
      end

      def call(env)
        app_result = app.call(env)

        status, headers, body = app_result

        return app_result unless qualify_for_adding_cjs?(status, headers)

        req = Rack::Request.new(env)

        return if req.xhr?

        new_body = ::Castle::Middleware::BodyModify.new.call(req, body)

        return app_result if new_body.nil?

        new_response = ::Rack::Response.new(new_body, status, headers)
        new_response.finish
      end

      def qualify_for_adding_cjs?(status, headers)
        status == 200 &&
          html?(headers) && !attachment?(headers) && !streaming?(headers)
      end

      private

      def html?(headers)
        headers['Content-Type'].to_s.include?('text/html')
      end

      def attachment?(headers)
        headers['Content-Disposition'].to_s.include?('attachment')
      end

      def streaming?(headers)
        headers['Transfer-Encoding'].to_s == 'chunked'
      end
    end
  end
end
