# frozen_string_literal: true

module Castle
  class Middleware
    # Configuration services (procs, lambdas) available to setup in configure block
    class SecureHeaders
      def initialize
        @can_append_nonce = ::SecureHeaders.respond_to?(:content_security_policy_script_nonce) &&
                            defined?(::SecureHeaders::Configuration) &&
                            !::SecureHeaders::Configuration.get.csp.opt_out? &&
                            !::SecureHeaders::Configuration.get.current_csp[:script_src].to_a.include?("'unsafe-inline'")
      end

      def call(env)
        return unless @can_append_nonce

        nonce = ::SecureHeaders.content_security_policy_script_nonce(::Rack::Request.new(env))
        " nonce=\"#{nonce}\""
      end
    end
  end
end
