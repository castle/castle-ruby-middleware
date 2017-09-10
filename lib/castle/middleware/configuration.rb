# frozen_string_literal: true

module Castle
  module Middleware
    # Configuration object for Middleware
    class Configuration
      %i[
        api_secret
        app_id
        auto_inject
        before_send
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
        @auto_inject = true
        @before_send = nil
        @pub_key = nil
      end
    end
  end
end
