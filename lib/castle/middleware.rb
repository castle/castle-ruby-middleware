require 'castle-rb'
require "castle/middleware/sensor"
require "castle/middleware/tracking"
require "castle/middleware/version"

module Castle
  module Middleware
    class << self
      attr_accessor :app_id
      attr_reader :api_secret

      def api_secret=(api_secret)
        Castle.api_secret = api_secret
        @api_secret = api_secret
      end
    end

    if defined?(Rails::VERSION) && Rails::VERSION::MAJOR >= 3 &&
      Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('3.2')
        require 'castle/middleware/railtie'
    end
  end
end
