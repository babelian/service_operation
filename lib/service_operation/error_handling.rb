# frozen_string_literal: true

module ServiceOperation
  # ActiveModel compatable ErrorHandling
  # depends on {Base#context} and {Errors}
  module ErrorHandling
    def errors
      @errors ||= Errors.new
    end

    # @param [Failure, Hash, nil] error(s) merge into {#errors}
    def fail!(error = {}, more = {})
      return unless error

      error = errors_from_error_code(error)
      errors.coerced_merge error

      more[:errors] ||= errors.merge(more[:errors] || {})

      context.fail! more
    end

    # fail if there {#errors} Hash has any contents
    def fail_if_errors!
      invalid? && fail!
    end

    def invalid?
      errors.any?
    end

    def valid?
      !invalid?
    end

    private

    # convert :error into 'Error' based on lookup in hash {ERRORS}
    def errors_from_error_code(error_code)
      return error_code unless error_code.is_a?(Symbol)

      return { error_code => send(error_code) } if attribute_exists?(error_code) # ?

      context.error_code = error_code
      errors = defined?(self.class::ERRORS) ? self.class::ERRORS : {}
      Array(errors[error_code] || error_code.to_s)
    end

    #
    # Method Missing
    #

    FAIL_IF_UNLESS_REGEXP = /^fail_(if|unless)_{0,1}([a-z_]*)!$/.freeze

    def fail_conditional_object(conditional, object_method, object, errors = nil)
      bool, errors = extract_bool_errors(object_method, object, errors)

      case conditional
      when 'if'
        fail!(errors) if bool
      when 'unless'
        fail!(errors) unless bool
      end
    end

    def extract_bool_errors(object_method, object, errors)
      # fail_if(object)
      if object_method == '?'
        [object, errors]
      # fail_if(object.method?)
      elsif object.respond_to?(object_method)
        [object.send(object_method), errors || object]
      # unknown
      else
        raise(NoMethodError, "#{object.class} does not respond to #{object_method}")
      end
    end

    def method_missing(method_name, *args, &block)
      # {if/unless}, method_name
      conditional, object_method = (method_name.to_s.match(FAIL_IF_UNLESS_REGEXP) || [])[1..2]

      if conditional
        fail_conditional_object(conditional, object_method + '?', *args)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name =~ FAIL_IF_UNLESS_REGEXP || super
    end
  end
end