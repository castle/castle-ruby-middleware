# frozen_string_literal: true

module Castle
  class Middleware
    # Configuration services (procs, lambdas) available to setup in configure block
    class ConfigurationServices
      %i[
        error_handler
        transport
        deny
        challenge
        logout
        provide_by_id
        provide_by_login_key
        validate_password
      ].each do |opt|
        attr_accessor opt
      end
    end
  end
end
