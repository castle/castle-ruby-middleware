# frozen_string_literal: true

module Castle
  class Middleware
    # Configuration options accessible for configure in mounted app

    class ConfigurationOptions
      %i[
        api_secret
        app_id
        tracker_url
        file_path
        logger
        events
        login
      ].each do |opt|
        attr_accessor opt
      end

      attr_reader :services

      def initialize
        @services = ConfigurationServices.new
      end
    end
  end
end
