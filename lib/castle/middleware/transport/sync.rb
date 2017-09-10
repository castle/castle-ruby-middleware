# frozen_string_literal: true

module Castle
  module Middleware
    module Transport
      # Send a track request to castle in sync mode
      module Sync
        def self.call(params, context)
          client_id, ip, headers = context.values_at(:client_id, :ip, :headers)
          Middleware.configuration.logger.debug(
            "[Castle] Tracking #{params[:name]}"
          )
          castle = ::Castle::API.new(client_id, ip, headers)
          castle.request('track', params)
        end
      end
    end
  end
end
