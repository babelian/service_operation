# frozen_string_literal: true

module ServiceOperation
  # Callback logic for integration with delayed_job or similar
  module Delay
    def self.included(base)
      base.extend ClassMethods
    end

    # Class Methods
    module ClassMethods
      def queue(input)
        if respond_to?(:delay)
          delay.call(input).id
        else
          call(input)
          nil
        end
      end
    end
  end
end
