# frozen_string_literal: true

module Castle
  module Middleware
    # Flatten nested Hashes
    class ParamsFlatter
      def self.call(object, prefix = nil)
        if object.is_a? Hash
          object.map do |key, value|
            if prefix
              call(value, "#{prefix}.#{key}")
            else
              call(value, key.to_s)
            end
          end.reduce(&:merge)
        else
          { prefix => object }
        end
      end
    end
  end
end
