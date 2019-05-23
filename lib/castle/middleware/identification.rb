# frozen_string_literal: true

module Castle
  class Middleware
    class Identification
      class << self
        def id(resource, config)
          return if resource.nil?

          resource.public_send(config.fetch('id')).to_s
        end

        def traits(resource, config)
          return {} if resource.nil?

          result = config.each_with_object({}) do |(name, value), acc|
            next if name.to_sym == :registered_at

            acc[name.to_sym] = resource.public_send(value)
          end

          result.tap do |r|
            r[:registered_at] = ::Time.parse(
              resource.public_send(config.fetch('registered_at')).to_s
            ).utc.iso8601(0)
          end
        end
      end
    end
  end
end
