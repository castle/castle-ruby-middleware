# frozen_string_literal: true

module Castle
  class Middleware
    class Identification
      class << self
        def id(resource, config)
          return false if resource.nil?

          resource.public_send(config.fetch('id')).to_s
        end

        def traits(resource, config)
          return {} if resource.nil?

          result = config.fetch('traits', {}).each_with_object({}) do |(name, value), acc|
            acc[name.to_sym] = resource.public_send(value)
          end
          result[:created_at] = Time.parse(resource.public_send(config.fetch('created_at')).to_s).utc.iso8601(0)
          result
        end
      end
    end
  end
end
