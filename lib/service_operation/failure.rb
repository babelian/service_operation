# frozen_string_literal: true

module ServiceOperation
  # StandardError for an operation
  class Failure < StandardError
    attr_reader :context

    def initialize(context = nil)
      @context = context
      super
    end
  end
end