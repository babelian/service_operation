# frozen_string_literal: true

require 'service_operation/params'

module ServiceOperation
  module Params
    # Build {Params::Attribute} DSL
    class DSL
      # @yield to the block containing the DSL
      # @return [Array<Attribute>]
      def self.run(&block)
        dsl = new
        dsl.instance_eval(&block)
        dsl.instance_variable_get('@attributes').freeze
      end

      def initialize
        @attributes = []
      end

      # rubocop:disable Naming/MethodName

      def Any(*subvalidators)
        Any.new(subvalidators)
      end

      def Anything
        Anything
      end

      def ArrayOf(element_validator)
        ArrayOf.new(element_validator)
      end

      def Bool
        Bool
      end

      def EnumerableOf(element_validator)
        EnumerableOf.new(element_validator)
      end

      # rubocop:enable Naming/MethodName

      # @todo: move
      def _query_params(default_sort: 'id')
        id :integer, optional: true
        ids [:integer], optional: true

        filter :hash, optional: true,
                      coerce: ->(f) { f.is_a?(Hash) ? f : Array(f).map { [f, nil] }.to_h }

        includes [:string], optional: true
        page :hash, optional: true, coerce: :json_api_page
        sort :string, optional: true, default: default_sort
      end

      private

      def def_attr(*args)
        @attributes << Attribute.define(*args)
      end

      def method_missing(name, *args)
        if respond_to_missing?(name)
          def_attr(name, *args)
        else
          super
        end
      end

      # any lowercase method name becomes an attribute
      def respond_to_missing?(method_name, _include_private = nil)
        first_letter = method_name.to_s.each_char.first
        first_letter.eql?(first_letter.downcase)
      end
    end
  end
end