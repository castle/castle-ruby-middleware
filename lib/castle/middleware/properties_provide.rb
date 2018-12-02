# frozen_string_literal: true

require 'castle/middleware/params_flattener'

module Castle
  class Middleware
    class PropertiesProvide
      class << self
        def call(request_params, properties_map)
          flat_params = ParamsFlattener.call(request_params)

          event_properties = properties_map.each_with_object({}) do |(property, param), acc|
            acc[property] = flat_params[param]
          end

          # Convert password to a boolean
          # TODO: Check agains list of known password field names
          if event_properties.key?(:password)
            event_properties[:password] = !event_properties[:password].to_s.empty?
          end

          event_properties
        end
      end
    end
  end
end
