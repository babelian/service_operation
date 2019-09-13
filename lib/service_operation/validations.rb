# frozen_string_literal: true

module ServiceOperation
  # Validations
  module Validations
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    # Class Methods
    module ClassMethods
    end

    def require_at_least_one_of(*args)
      # mothballed:
      # @option args.last [Boolean] :context whether to check context directly rather than send()
      #                                      use if you want to prevent an auto generated value.
      # options = args.last.is_a?(Hash) ? args.pop : {}
      # base = options[:context] ? context : self

      base = self
      return if args.any? { |k| base.send(k) }

      errors.add(:base, "One of #{args.map(&:to_s).join(', ')} required.")
    end
  end
end
