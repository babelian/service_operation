# frozen_string_literal: true

require 'service_operation/params'

module ServiceOperation
  KEYWORDS = [
    :base, :errors, :error_code, :status_code
  ].freeze

  module Params
    #
    # Represents a single attribute of a value class
    #
    class Attribute
      OPTIONS = [:name, :validator, :coercer, :default, :log, :optional].freeze

      # Types of validation classes that can be expanded
      EXPANDABLE_VALIDATORS = %w[Array Symbol String].freeze

      # Typical coercions from web/string parameters
      PARAM_COERCIONS = {
        date: ->(d) { d.is_a?(String) ? Date.parse(d) : d },
        integer: ->(o) { o && o != '' ? o.to_i : nil },
        string: ->(o) { o && o != '' ? o.to_s : nil }
      }.freeze

      COERCIONS = {
        'Integer' => PARAM_COERCIONS[:integer],
        'String' => PARAM_COERCIONS[:string],
        'EnumerableOf(Integer)' => ->(o) { Array(o).map(&:to_i) },
        'EnumerableOf(String)' => ->(o) { Array(o).map(&:to_s) },

        json_api_page: lambda do |o|
          h = Hash(o)
          h[:size] = h[:size].to_i if h && h[:size].present?
          h
        end
      }.freeze

      #
      # Class Methods
      #

      class << self
        def define(*args)
          options = extract_options(args)
          name, validator = args
          validator ||= Anything

          raise "#{name.inspect} is a keyword" if KEYWORDS.include?(name)

          if EXPANDABLE_VALIDATORS.include?(validator.class.name)
            validator = expand_validator(validator)
            options[:coerce] = COERCIONS[validator.name] || true if options[:coerce].nil?
          end

          # options[:coerce] = COERCIONS[validator.name] || options[:coerce]
          options[:coercer] = options.delete(:coerce)

          new options.merge(name: name, validator: validator)
        end

        private

        # activesupport/lib/active_support/inflector/methods.rb
        # rubocop:disable all
        def camelize(string, uppercase_first_letter = true)
          if uppercase_first_letter
            string = string.sub(/^[a-z\d]*/) { $&.capitalize }
          else
            string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { $&.downcase }
          end
          string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
        end
        # rubocop:enable all

        def expand_validator(validator)
          case validator
          when Array
            EnumerableOf.new(*validator.map { |v| expand_validator(v) })
          when Symbol, String
            validator = 'bool' if validator.to_s == 'boolean'
            Params.const_get camelize(validator.to_s)
          else
            validator
          end
        end

        def extract_options(args)
          args.last.is_a?(Hash) ? args.pop : {}
        end
      end

      #
      # Instance Methods
      #

      attr_reader :name, :validator, :coercer, :default, :log, :optional, :options

      def initialize(options = {})
        @name = options[:name].to_sym
        @validator  = options[:validator]
        @coercer    = options[:coercer]
        @default    = options[:default]
        @log        = options.fetch(:log) { true }
        @optional   = options.fetch(:optional) { false }
        @options    = options.reject { |k, _v| OPTIONS.include?(k) }

        freeze
      end

      def ==(other)
        name == other.name
      end

      def from(raw_value, klass = nil)
        raw_value = (default.respond_to?(:call) ? default.call : default) if raw_value.nil?
        coerce(raw_value, klass)
      end

      def error(value)
        return if validate?(value)

        if required? && value.nil?
          "can't be blank"
        else
          "must be typecast '#{validator.name}'"
        end
      end

      def optional?
        optional == true
      end

      def required?
        !optional
      end

      def validate?(value)
        # special exception to prevent Object === nil from validating
        return false if value.nil? && !optional

        optional || validator === value # rubocop:disable Style/CaseEquality
      end

      private

      def coerce(value, klass)
        return value unless coercer && !value.nil? # coercion not enabled or value was nil
        return klass.public_send(coercion_method, value) if klass.respond_to?(coercion_method)

        if coercer.respond_to?(:call)
          coercer.call value
        else
          value
        end
      end

      def coercion_method
        "coerce_#{name}"
      end
    end
  end
end