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

  let(:actual_output) do
    operation.call(input)
  end

  let(:expected_output) do
    context = ServiceOperation::Context.new input.merge(output)
    context.fail! if context.errors
    context
  rescue ServiceOperation::Failure
    context
  end

  context 'success' do
    let(:input) { { param1: 1 } }
    let(:output) { { return1: '1' } }

    it 'allow_operation(operation, input) outputs a successful Context' do
      allow_operation(operation, input, output)

      expect(actual_output).to eq expected_output
      expect(actual_output).to be_success
      expect(operation).to have_received(:call).with(input)
    end

    it 'allow_operation(operation, input) { |args| output } works' do
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

    it 'outputs a failed Context' do
      allow_operation(operation, input, output)

      expect(actual_output).to eq expected_output
      expect(actual_output).to be_failure

      expect(operation).to have_received(:call).with(input)
    end
  end
end