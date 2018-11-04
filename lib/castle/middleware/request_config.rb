# frozen_string_literal: true

module Castle
  module Middleware
    class RequestConfig
      attr_reader :user_id
      attr_reader :traits

      def identify(user_id, traits)
        @user_id = user_id
        @traits = traits
      end
    end
  end
end
