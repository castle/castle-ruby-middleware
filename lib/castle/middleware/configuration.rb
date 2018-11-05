# frozen_string_literal: true

require 'castle-rb'
require 'yaml'

module Castle
  class Middleware
    # Configuration object for Middleware
    class Configuration
      extend Forwardable
      attr_reader :options
      def_delegators :@options,
                     :logger, :transport, :api_secret, :app_id, :tracker_url, :services,
                     :events, :login
      # :deny, :challenge, :logout, :provide_by_id, :provide_by_login_key, :validate_password
      def_delegators :@middleware, :log, :track

      def initialize(options = nil)
        @options = options
        @middleware = Middleware.instance
        setup
      end

      # Reset to default options
      def setup
        options.file_path ||= 'config/castle.yml'
        options.events ||= {}
        services.transport ||= lambda do |context, options|
          track(context, options)
        end
        # Forward setting to Castle SDK
        Castle.api_secret = api_secret
        load_config_file
      end

      def load_config_file
        file_config = YAML.load_file(options.file_path)
        options.events = (options.events || {}).merge(file_config['events'] || {})
        options.login = (options.events || {}).merge(file_config['login'] || {})
      rescue Errno::ENOENT => e
        log(:error, '[Castle] No config file found')
      rescue Psych::SyntaxError
        log(:error, '[Castle] Invalid YAML in config file')
      end
    end
  end
end
