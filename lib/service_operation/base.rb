# frozen_string_literal: true

# ServiceOperation
module ServiceOperation
  # Base
  module Base
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        include Delay
        include ErrorHandling
        include Hooks
        include Params
        include Validations
      end
    end

    #
    # Class Methods
    #
    module ClassMethods
      def call(context = {})
        new(context).tap(&:run).context
      end

      def call!(context = {})
        new(context).tap(&:run!).context
      end

      # Allow use via ProxyAction
      def allow_remote!
        @allow_remote = true
      end

      def allow_remote
        @allow_remote || false
      end
    end

    #
    # Instance Methods
    #

    def initialize(context = {})
      @context = Context.build(context)
    end

    def call
      nil
    end

    def context(attribute_name = nil, &block)
      if block_given?
        attribute_name ||= caller(1..1).first[/`([^']*)'$/, 1]
        @context.fetch(attribute_name, &block)
      else
        @context
      end
    end

    def run
      run!
    rescue Failure
      nil
    end

    def run!
      with_hooks { fail_if_errors! || skip || call } && true
    end

    def skip
      context.skip || false
    end

    def skip!
      context.skip = true
    end
  end
end