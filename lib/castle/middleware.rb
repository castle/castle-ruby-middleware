# frozen_string_literal: true

require 'castle/middleware/errors'
require 'castle/middleware/configuration'
require 'castle/middleware/configuration/options'
require 'castle/middleware/configuration/services'
require 'castle/middleware/configuration/validate'
require 'castle/middleware/sensor'
require 'castle/middleware/tracking'
require 'castle/middleware/authenticating'
require 'castle/middleware/version'
require 'singleton'

module Castle
  # Main middleware definition
  class Middleware
    include ::Singleton

    def call_error_handler(exception)
      return unless configuration.services.error_handler

      configuration.services.error_handler.call(exception)
    end

    def configure
      raise ArgumentError unless block_given?

      @configuration_options = Configuration::Options.new
      yield(@configuration_options)
      @configuration = nil
      validate
    end

    def validate
      Configuration::Validate.new.call(@configuration_options)
    end

    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new(@configuration_options)
    end

    def log(level, message)
      return unless configuration.logger

      configuration.logger.public_send(level.to_s, message)
    end

    def track(context, options)
      do_request(:track, context, options)
    end

    def authenticate(context, options)
      do_request(:authenticate, context, options)
    end

    def do_request(meth, context, options)
      log(:debug, "[Castle] #{meth} #{options[:event]}")
      ::Castle::Client.new(context).public_send(meth, options)
    rescue Castle::Error => e
      log(:warn, "[Castle] Can't send #{meth} request because #{e} exception")
      call_error_handler(e)
    end

    class << self
      def configure(&block)
        instance.configure(&block)
      end
    end
  end
end
