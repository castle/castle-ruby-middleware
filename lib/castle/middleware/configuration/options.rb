# frozen_string_literal: true

module Castle
  class Middleware
    # Configuration options accessible for configure in mounted app
    class Configuration
      class Options
        %i[
          api_secret
          api_options
          app_id
          tracker_url
          autoforward_client_id
          cookie_domain
          security_headers
          file_path
          logger
          events
          identify
          user_traits
        ].each do |opt|
          attr_accessor opt
        end

        attr_reader :services

        def initialize
          @events = {}
          @security_headers = false
          @api_options = {}
          @identify = {}
          @user_traits = {}
          @services = ::Castle::Middleware::Configuration::Services.new
        end
      end
    end
  end
end
