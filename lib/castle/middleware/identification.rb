# frozen_string_literal: true

module Castle
  class Middleware
    class Identification
      class << self
        def id(resource, config)
          resource.public_send(config['id']).to_s
        end

        def traits(resource, config)
          config.fetch('traits', {}).each_with_object({}) do |(name, value), acc|
            acc[name.to_sym] = resource.public_send(value)
          end
        end
      end
    end
  end
end
