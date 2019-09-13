# frozen_string_literal: true

# rubocop:disable Style/CaseEquality

require 'service_operation/params'

module ServiceOperation
  module Params
    # Matches true or false
    module Bool
      # @return [Boolean]
      def self.===(other)
        true.equal?(other) || false.equal?(other)
      end
    end

    # Matches any value
    module Anything
      # @return [true]
      def self.===(_other)
        true
      end
    end

    # @abstract for Enumerator based types
    class EnumType
      def ==(other)
        other.is_a?(self.class) && other.inspect == inspect
      end

      # @abstract
      def initialize(*_args)
        freeze
      end

      def inspect
        "<#{name}>"
      end

      def name
        type.name
      end

      # @abstract
      def type
        raise('define in sub class')
      end
    end

    # Matches any sub type
    class Any < EnumType
      attr_reader :sub_types

      def initialize(sub_types)
        @sub_types = Array(sub_types)
        super
      end

      # @return [Boolean]
      def ===(other)
        sub_types.any? { |sv| sv === other }
      end

      # @return [String] representation of class and its sub classes
      def name
        "Any(#{sub_types.map(&:name).join(', ')})"
      end
    end

    # Matches an Enumerable with specific sub types
    # @example EnumerableOf.new(String, Integer)
    class EnumerableOf < EnumType
      attr_reader :element_type

      def initialize(*args)
        @element_type = args.length == 1 ? args.first : Any.new(args)

        super
      end

      # @return [Boolean]
      def ===(other)
        type === other && other.all? { |element| element_type === element }
      end

      def name
        "#{super}Of(#{element_type.name})"
      end

      def type
        Enumerable
      end
    end

    # Matches an Array with specific sub types
    # @example ArrayOf.new(String)
    # @example ArrayOf.new(String, Integer)
    class ArrayOf < EnumerableOf
      def type
        Array
      end
    end
  end
end

# rubocop:enable Style/CaseEquality