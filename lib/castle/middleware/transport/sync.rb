# frozen_string_literal: true

module Castle
  module Middleware
    module Transport
      # Send a track request to castle in sync mode
      module Sync
        def self.call(context, options)
          Middleware.track(context, options)
        end
      end
    end
  end
end
