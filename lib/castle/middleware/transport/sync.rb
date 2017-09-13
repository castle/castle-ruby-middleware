# frozen_string_literal: true

module Castle
  module Middleware
    module Transport
      # Send a track request to castle in sync mode
      module Sync
        def self.call(params, context)
          Middleware.track(params, context)
        end
      end
    end
  end
end
