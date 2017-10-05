# frozen_string_literal: true

module Castle
  module Middleware
    # Map a request path to a Castle event name
    class EventMapper
      Object = Struct.new(:event, :method, :path, :status, :properties)

      attr_accessor :mappings

      def initialize
        @mappings = []
      end

      def add(event, conditions)
        raise ArgumentError unless conditions.is_a?(::Hash)
        conditions = conditions.each_with_object({}) do |(k, v), hash|
          hash[k.to_sym] = v || ''
        end
        @mappings << Object.new(
          event.to_s,
          conditions[:method].to_s,
          conditions[:path],
          conditions[:status].to_s,
          conditions[:properties] || {}
        )
      end

      def events
        @mappings.map(&:event)
      end

      def find(conditions)
        @mappings.detect { |mapping| self.class.match?(mapping, conditions) }
      end

      def find_by_rack_request(result, request)
        find(
          status: result.first, # Rack status code
          method: request.request_method,
          path: request.path
        )
      end

      def size
        @mappings.size
      end

      def self.build(config)
        raise ArgumentError, 'Invalid format' unless config.is_a?(::Hash)
        config.each_with_object(new) do |(event, conditions), mapping|
          conditions = [conditions] unless conditions.is_a?(::Array)
          conditions.each { |c| mapping.add(event, c) }
        end
      end

      def self.match?(mapping, conditions)
        status, mtd, path = conditions.values_at(:status, :method, :path)
        return false if [status, mtd, path].include?(nil)
        mapping.status.match(status.to_s) &&
          mapping.method.match(mtd.to_s) &&
          mapping.path.match(path.to_s)
      end
    end
  end
end
