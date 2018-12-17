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

          password_fields = event_properties.keys.select { |key| key.to_s.include?('password') }

          # Convert password to a boolean
          password_fields.each do |field_name|
            event_properties[field_name] = !event_properties[field_name].to_s.empty?
          end

          event_properties
        end
      end
    end
  end
end
