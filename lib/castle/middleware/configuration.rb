# frozen_string_literal: true

require 'castle-rb'
require 'yaml'

module Castle
  module Middleware
    # Configuration object for Middleware
    class Configuration
      extend SingleForwardable
      attr_accessor :options, :events
      def_single_delegators :options, :logger, :transport, :error_handler, :api_secret

      def initialize(options = nil)
        self.options = options
        setup
      end

      # Reset to default options
      def setup
        options.file_path ||= 'config/castle.yml'
        options.transport = lambda do |context, options|
          Castle::Middleware.track(context, options)
        end
        # Forward setting to Castle SDK
        Castle.api_secret = api_secret
        load_config_file
      end

      def load_config_file
        file_config = YAML.load_file(options.file_path)
        self.events = file_config['events'] || {}
      rescue Errno::ENOENT
        Castle::Middleware.log(:error, '[Castle] No config file found')
      rescue Psych::SyntaxError
        Castle::Middleware.log(:error, '[Castle] Invalid YAML in config file')
      end
    end
  end
end
