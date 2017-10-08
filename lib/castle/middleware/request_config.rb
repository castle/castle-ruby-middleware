# frozen_string_literal: true

module Castle
  module Middleware
    class RequestConfig
      attr_reader :user_id
      attr_reader :traits
      attr_reader :props

      def identify(user_id, traits)
        @user_id = user_id
        @traits = traits
      end

      def properties(props)
        @props = props
      end
    end
  end
end
