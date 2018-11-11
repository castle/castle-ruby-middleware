# frozen_string_literal: true

module Castle
  class Middleware
    class RequestConfig
      attr_reader :user_id
      attr_reader :traits
      attr_reader :props

      def identify(user_id, traits)
        @user_id = user_id
        @traits = traits
      end

      def clear
        @user_id = nil
        @traits = nil
      end

      def properties(props)
        @props = props
      end
    end
  end
end
