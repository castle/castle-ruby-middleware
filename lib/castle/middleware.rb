# frozen_string_literal: true

require 'castle/middleware/configuration'
require 'castle/middleware/configuration_options'
require 'castle/middleware/event_mapper'
require 'castle/middleware/params_flattener'
require 'castle/middleware/sensor'
require 'castle/middleware/tracking'
require 'castle/middleware/version'

module Castle
  # Main middleware definition
  module Middleware
    class << self
      attr_writer :configuration

      def call_error_handler(exception)
        return unless configuration.error_handler
        configuration.error_handler.call(exception)
      end

      def configure
        raise ArgumentError unless block_given?
        @configuration_options = ConfigurationOptions.new
        yield(@configuration_options)
        @event_mapping = nil
      end

      def configuration
        @configuration ||= Configuration.new(@configuration_options)
      end

      def event_mapping
        @event_mapping ||= EventMapper.build(configuration.events)
      end

      def log(level, message)
        return unless Middleware.configuration.logger
        Middleware.configuration.logger.public_send(level.to_s, message)
      end

      def track(context, options)
        log(:debug, "[Castle] Tracking #{options[:event]}")
        castle = ::Castle::Client.new(context)
        castle.track(options)
      rescue Castle::Error => e
        log(:warn, "[Castle] Can't send tracking request because #{e} exception")
        call_error_handler(e)
      end

      def authenticate(context, options)
        log(:debug, "[Castle] Authenticating #{options[:event]}")
        castle = ::Castle::Client.new(context)
        castle.authenticate(options)
      rescue Castle::Error => e
        log(:warn, "[Castle] Can't send authenticating request because #{e} exception")
        call_error_handler(e)
      end
    end
  end
end
