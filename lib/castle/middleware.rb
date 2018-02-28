# frozen_string_literal: true

require 'castle/middleware/configuration'
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
        return unless configuration.error_handler.is_a?(Proc)
        configuration.error_handler.call(exception)
      end

      def configure
        raise ArgumentError unless block_given?
        yield(configuration)
        @event_mapping = nil
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def event_mapping
        @event_mapping ||= EventMapper.build(configuration.events)
      end

      def log(level, message)
        return unless Middleware.configuration.logger
        Middleware.configuration.logger.public_send(level.to_s, message)
      end

      def track(context, options)
        log(:debug, "[Castle] Tracking #{options[:name]}")
        castle = ::Castle::Client.new(context, options)
        castle.track(options)
      rescue Castle::Error => e
        log(:warn, "[Castle] Can't send tracking request because #{e} exception")
        call_error_handler(e)
      end
    end

    if defined?(Rails::VERSION) && Rails::VERSION::MAJOR >= 3 &&
       Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('3.2')
      require 'castle/middleware/railtie'
    end
  end
end
