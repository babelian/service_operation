# frozen_string_literal: true

require 'ostruct'

module ServiceOperation
  # Context for an Operation
  class Context < OpenStruct
    CALLER_NAME_REGEXP = /`(rescue in |)([^']*)'$/

    #
    # Class Methods
    #

    def self.build(context = {})
      self === context ? context : new(context) # rubocop:disable Style/CaseEquality
    end

    #
    # Instance Methods
    #

    # Fixes stack loop issue with OpenStruct
    # @requires ActiveModel::Serializers
    def as_json(*args)
      to_h.as_json(*args)
    end

    def fail!(context = {})
      context.each { |k, v| send("#{k}=", v) }
      @failure = true

      raise Failure, self
    end

    # Use in the Operation class to create eager loading objects:
    #
    # @example
    #   def Operation#record
    #     context.coerce_if(Integer, String) { |name| Model.find_by_param(name) }
    #   end
    #
    #  Operation.call(record: 'something').record == <Model name='something'>
    def coerce_if(*klasses)
      field = klasses.shift if klasses.first.is_a?(Symbol)
      field ||= caller(1..1).first[CALLER_NAME_REGEXP, 2] # method name fetch was called from
      self[field] = yield(self[field]) if klasses.any? { |k| self[field].is_a?(k) }
      self[field]
    end

    # @example
    #   fetch(:field, 'value')
    # @example
    #   fetch(:field) { 'value' }
    # @example will infer field name from enclosing method name
    #   def enclosing_method
    #     context.fetch { 'value' }
    #   end
    # @example
    #   def enclosing_method
    #     context.fetch 'value'
    #   end
    def fetch(*args)
      if !block_given? && args.length == 1 # context.fetch 'value'
        new_value = args.first
      else
        field, new_value = args
      end

      field ||= caller(1..1).first[CALLER_NAME_REGEXP, 2] # method name fetch was called from

      # field is already set
      value = send(field)
      return value if value

      # context.fetch { block }
      if block_given?
        begin
          value ||= yield
        rescue StandardError => e
          # apply if this context to the field, if this is first instance of this error being raised
          self[field] = e.context if e.respond_to?(:context) &&
                                     e.context.is_a?(self.class) &&
                                     e.context != self &&
                                     e.context.not_yet_raised

          raise e
        end
      end

      value ||= new_value

      self[field] = value

      value
    end

    # @return [true, false] first call returns false, after that true.
    def not_yet_raised
      if @already_raised
        false
      else
        @already_raised = true
      end
    end

    def failure?
      @failure || false
    end

    def success?
      !failure?
    end

    def to_h(*args)
      if args.any?
        super().slice(*args)
      else
        super()
      end
    end
  end
end