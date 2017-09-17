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

      def track(params, context)
        client_id, ip, headers = context.values_at(:client_id, :ip, :headers)
        log(:debug, "[Castle] Tracking #{params[:name]}")
        castle = ::Castle::API.new(client_id, ip, headers)
        castle.request('track', params)
      end
    end

    if defined?(Rails::VERSION) && Rails::VERSION::MAJOR >= 3 &&
       Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('3.2')
      require 'castle/middleware/railtie'
    end
  end
end
