# frozen_string_literal: true

require 'castle-rb'
require 'castle/middleware/transport/sync'
require 'yaml'

module Castle
  module Middleware
    # Configuration object for Middleware
    class Configuration
      %i[
        api_secret
        app_id
        auto_insert_middleware
        events
        logger
        transport
        pub_key
      ].each do |opt|
        attr_accessor opt
      end

      def initialize
        reset!
        load_config_file!
      end

      def load_config_file!
        file_config = YAML.load_file('castle.yml')
        self.events = file_config['events'] || {}
      rescue Errno::ENOENT
        logger.send('warn', '[Castle] No config file found')
      rescue Psych::SyntaxError
        logger.send('error', '[Castle] Invalid YAML in config file')
      end

      # Reset to default options
      def reset!
        @api_secret = nil
        @app_id = nil
        @auto_insert_middleware = true
        @events = {}
        @logger = defined?(::Rails) ? Rails.logger : nil
        @transport = Transport::Sync
        @pub_key = nil
      end

      # Forward setting to Castle SDK
      def api_secret=(api_secret)
        @api_secret = Castle.api_secret = api_secret
      end
    end
  end
end
