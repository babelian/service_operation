require 'spec_helper'
require 'service_operation/spec/support/stub_helpers'

RSpec.describe ServiceOperation::Spec::Support::StubHelpers do
  include described_class

  let(:operation) do
    Class.new do
      include ServiceOperation::Base

      input do
        param1 :integer
      end

      output do
        return1 :string
      end

      def call
        raise 'spec fail #call should not be called'
      end
    end
  end

  let(:input) { { param1: 1 } }
  let(:output) { { return1: '1' } }

  let(:actual_output) do
    operation.call(input)
  end

  let(:actual_output!) do
    operation.call!(input)
  end

  let(:expected_input) do
    ServiceOperation::Context.new input
  end

  let(:expected_output) do
    context = ServiceOperation::Context.new input.merge(output)
    context.fail! if context.errors
    context
  rescue ServiceOperation::Failure => e
    context
  end

  #
  # #allow_operation
  #

  describe '#allow_operation' do
    context 'success' do
      it '(operation, input, output) outputs a successful Context' do
        allow_operation(operation, input, output)

        expect(actual_output).to eq expected_output
        expect(actual_output).to be_success
        expect(operation).to have_received(:call).with(input)
      end

      it '(operation, input) { |args| output } works' do
        allow_operation(operation, input) do |args|
          expect(args).to eq(input)
          output
        end
        expect(actual_output).to eq expected_output
      end
    end

    context 'failure' do
      let(:input) { { param1: nil } }
      let(:output) { { errors: { param1: ["can't be blank"] } } }

      it '(operation, incomplete_input, output_with_errors) outputs a failed Context' do
        allow_operation(operation, input, output)

        expect(actual_output).to eq expected_output
        expect(actual_output).to be_failure

        expect(operation).to have_received(:call).with(input)
      end
    end
  end

  describe '#allow_operation! uses receive(:call!) instead of receive(:call)' do
    let(:actual_output) do
      operation.call!(input)
    end

    it '(operation, input, output) works' do
      allow(operation).to receive(:call) # make sure its not called

      allow_operation!(operation, input, output)

      expect(actual_output).to eq expected_output
      expect(operation).to have_received(:call!)

      expect(operation).not_to have_received(:call) # double check
    end

    it '(operation, input) { |args| output } works' do
      allow_operation!(operation, input) do |args|
        expect(args).to eq(input)
        output
      end
      expect(actual_output).to eq expected_output
    end
  end

  #
  # #expect_operation
  #

  describe '#expect_operation' do
    it '(operation, input)' do
      allow(operation).to receive(:call).with(input) { output }
      actual_output
      expect_operation(operation, input)
    end
  end

  describe '#expect_operation! uses receive(:call!) instead of receive(:call)' do
    it '(operation, input)' do
      allow(operation).to receive(:call)

      allow(operation).to receive(:call!).with(input) { output }

      actual_output!
      expect_operation!(operation, input)

      expect(operation).not_to have_received(:call)
    end
  end
end