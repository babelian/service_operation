# frozen_string_literal: true

# rubocop:disable Style/SafeNavigation
require 'service_operation/params/types'

module ServiceOperation
  # Params depends on {Hooks}
  module Params
    autoload :Attribute, 'service_operation/params/attribute'
    autoload :DSL, 'service_operation/params/dsl'

    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    # ClassMethods
    module ClassMethods
      # @example
      #   params do
      #     param1, :integer, coerce: true
      #   end
      def params(&block)
        @params ||= superclass && superclass.respond_to?(:params) ? superclass.params.dup : []

        if block_given?
          @params += Params::DSL.run(&block)
          define_params_hooks
        end

        @params = @params.reverse.uniq(&:name).reverse
        @params
      end

      alias input params

      # @example
      #   returns do
      #     result, [:string]
      #     log_data, [:string], optional: true
      #   end
      def returns(&block)
        @returns ||= superclass && superclass.respond_to?(:returns) ? superclass.returns.dup : []

        @returns += Params::DSL.run(&block) if block_given?

        @returns = @returns.reverse.uniq(&:name).reverse
        @returns
      end

      def attributes
        (returns + params).uniq(&:name) # returns first to preserve log: option
      end

      # should only be called by Instance after all attributes have been defined
      def attribute_names
        @attribute_names ||= attributes.map(&:name)
      end

      alias output returns

      def remove_params(*args)
        params.delete_if { |a| args.include?(a.name) }
      end

      private

      def define_params_hooks
        return if @defined_params_hooks

        before :validate_params
        after :validate_returns
        @defined_params_hooks = true
      end
    end

    # InstanceMethods
    module InstanceMethods
      private

      # coerces param and adds an error if it fails to validate type
      def validate_params
        validate_attributes(self.class.params, coerce: true)
      end

      def validate_returns
        validate_attributes(self.class.returns)
      end

      def validate_attributes(attributes, coerce: false)
        attributes.each do |attr|
          value = attr.optional ? context[attr.name] : send(attr.name)

          context[attr.name] = value = attr.from(value, self.class) if coerce

          if error = attr.error(value)
            errors.add(attr.name, error)
          end
        end

        context.fail!(errors: errors) if errors.any?
      end

      #
      # Method Missing to delegate to params/context
      #

      # delegate to context if calling an explicit param
      def method_missing(method_name, *args, &block)
        method_name_without_q = method_name.to_s.delete('?').to_sym
        if attribute_exists?(method_name_without_q)
          context.send(method_name_without_q, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        attribute_exists?(method_name) || super
      end

      def attribute_exists?(method_name)
        self.class.attribute_names.include?(method_name)
      end
    end
  end
end

# rubocop:enable Style/SafeNavigation