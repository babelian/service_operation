module ServiceOperation
  module Spec
    module Support
      # Stub Helpers
      module StubHelpers
        def allow_operation(operation_class, input = any_args, output = nil)
          allow(operation_class).to receive(:call).with(input) do |args|
            output ||= yield(args)
            operation = operation_class.new input.merge(output)
            operation.validated_context
          end
        end
      end
    end
  end
end