# frozen_string_literal: true

module ServiceOperation
  # mount in Rails routes.rb with mount(ServiceName => '/path')
  # @todo remove ActionDispatch dependency
  class RackMountable
    include ServiceOperation::Base

    IS_RACK_REQUEST_REGEXP = /SERVER_NAME|rack\./.freeze

    allow_remote!

    params do
      request optional: true
    end

    returns do
      body Any(String, Hash)
      headers Hash
      status String
    end

    after do
      context.body = context.body || context.message || context.error || ''
      context.headers ||= {}
      context.status = (context.status || 200).to_s
    end

    #
    # Class Methods
    #

    class << self
      alias base_call call

      # Wrap the call method with a check to see if its a rack request
      # If so merge in request.params and return a rack response
      def call(*args)
        if request = rack_request(*args)
          rack_response base_call(request: request)
        else
          base_call(*args)
        end
      end

      private

      #
      # Request
      #

      def rack_request(*args)
        return unless args.first.is_a?(Hash) && args.first.keys.grep(IS_RACK_REQUEST_REGEXP).any?

        ActionDispatch::Request.new(args.first)
      end

      #
      # Response
      #

      def rack_response(context)
        [context.status, context.headers, rack_body(context)]
      end

      def rack_body(context)
        body = context.body
        body = contextbody.to_json if body.is_a?(Hash)
        body = [body] unless body.is_a?(Array)
        body
      end
    end
  end
end