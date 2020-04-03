# frozen_string_literal: true

require 'singleton'
require 'castle-rb'
require 'yaml'

module Castle
  class Middleware
    # Configuration object for Middleware
    class Configuration
      extend Forwardable
      attr_reader :options
      def_delegators :@options,
                     :logger, :transport, :api_secret, :app_id,
                     :tracker_url, :autoforward_client_id, :cookie_domain,
                     :services, :api_options, :cjs_path,
                     :events, :identify, :user_traits, :security_headers
      def_delegators :@middleware, :log, :track

      def initialize(options = nil)
        @options = options
        @middleware = Middleware.instance
        reload
      end

      # Reset to default options
      def reload
        services.transport ||= lambda do |context, options|
          track(context, options)
        end
        # Forward setting to Castle SDK
        Castle.configure do |config|
          api_options.each do |key, value|
            config.public_send("#{key}=", value)
          end
          config.api_secret = api_secret
        end
        load_config_file if options.file_path
      end

      def load_config_file
        file_config = YAML.load_file(options.file_path)
        options.events = (options.events || {}).merge(file_config['events'] || {})
        options.identify = (options.identify || {}).merge(file_config['identify'] || {})
        options.api_options = (options.api_options || {}).merge(file_config['api_options'] || {})
        options.user_traits = (options.user_traits || {}).merge(file_config['user_traits'] || {})
      rescue Errno::ENOENT
        log(:error, '[Castle] No config file found')
      rescue Psych::SyntaxError
        Caste::Middleware::ConfigError.new('[Castle] Invalid YAML in config file')
      end
    end
  end
end
