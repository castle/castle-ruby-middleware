# frozen_string_literal: true

module Castle
  class Middleware
    # Configuration services (procs, lambdas) available to setup in configure block
    class Configuration
      class Services
        %i[
          error_handler
          transport
          deny
          challenge
          provide_user
        ].each do |opt|
          attr_accessor opt
        end
      end
    end
  end
end
