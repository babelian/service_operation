# frozen_string_literal: true

module ServiceOperation
  # Error object with minimal compatibility with ActiveModel style errors
  class Errors < Hash
    # @example
    #   add(:attr, 'error1', 'error2')
    # @param [Symbol] attr to add error to
    def add(attr, *args)
      return self if args.empty?

      self[attr] ||= []
      self[attr] += args.flatten

      self
    end

    # @param error_hash pass any type of error and it will be normalized to { attr: ['error'] }
    def coerced_merge(error_hash)
      ensure_error_hash(error_hash).each do |key, error|
        object_to_array(error).each { |errors| add(key, *errors) }
      end

      self
    end

    private

    # @return [Hash] formatted { attribute: ['error'] }
    def ensure_error_hash(object)
      object = object.context.errors || object if object.is_a?(Failure)
      object = object.errors.to_h if object.respond_to?(:errors)
      object = object.messages.to_h if object.respond_to?(:messages)
      object = { base: object } unless object.is_a?(Hash)
      object
    end

    # convert ActiveRecord:Base / ActiveModel::Errors to an array
    def object_to_array(errors)
      errors = errors.message if errors.respond_to?(:message) # StandardError
      errors = errors.errors if errors.respond_to?(:errors)
      errors = errors.messages if errors.respond_to?(:full_messages)
      Array(errors).compact
    end
  end
end
