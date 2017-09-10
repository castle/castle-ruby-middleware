# frozen_string_literal: true

require 'castle/middleware/transport/sync'

module Castle
  module Middleware
    # Configuration object for Middleware
    class Configuration
      %i[
        api_secret
        app_id
        auto_insert_middleware
        logger
        transport
        pub_key
      ].each do |opt|
        attr_accessor opt
      end

      def initialize
        reset!
      end

      # Reset to default options
      def reset!
        @api_secret = nil
        @app_id = nil
        @auto_insert_middleware = true
        @logger = defined?(::Rails) ? Rails.logger : nil
        @transport = Transport::Sync
        @pub_key = nil
      end
    end
  end
end
