# frozen_string_literal: true

module Castle
  module Middleware
    class ConfigurationOptions
      %i[
        api_secret
        app_id
        auto_insert_middleware
        error_handler
        file_path
        logger
        transport
      ].each do |opt|
        attr_accessor opt
      end

      def initialize
        self.auto_insert_middleware = false
      end
    end
  end
end
