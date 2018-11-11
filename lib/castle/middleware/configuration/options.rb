# frozen_string_literal: true

module Castle
  class Middleware
    # Configuration options accessible for configure in mounted app
    class Configuration
      class Options
        %i[
          api_secret
          app_id
          tracker_url
          security_headers
          file_path
          logger
          events
          login_event
        ].each do |opt|
          attr_accessor opt
        end

        attr_reader :services

        def initialize
          @events = {}
          @security_headers = false
          @login_event = {}
          @services = ::Castle::Middleware::Configuration::Services.new
        end
      end
    end
  end
end
