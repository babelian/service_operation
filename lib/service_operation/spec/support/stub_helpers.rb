module ServiceOperation
  module Spec
    module Support
      # Stub Helpers
      module StubHelpers
        def allow_operation(operation_class, input = nil, output = nil, receive_method = :call)
          expectation = receive(receive_method)
          expectation = expectation.with(input) if input

          allow(operation_class).to expectation do |args|
            output ||= yield(args)
            output = (input || {}).merge(output)
            operation = operation_class.new output
            operation.validated_context
          end
        end

        def allow_operation!(*args)
          args << :call!
          allow_operation(*args)
        end

        def expect_operation(operation_class, input = nil, receive_method = :call)
          expectation = have_received(receive_method)
          expectation = expectation.with(input) if input

          expect(operation_class).to expectation
        end

        def expect_operation!(*args)
          args << :call!
          expect_operation(*args)
        end
      end
    end
  end
end