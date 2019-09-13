# frozen_string_literal: true

shared_context 'operation', type: :operation do
  let(:input) { {} }
  let(:output) { described_class.call(input) }
  let(:outputs) { [] }
  let(:errors) { output.errors || [] }

  private

  def call_operation
    outputs << described_class.call(input)
    outputs.last
  end

  def call_operation!
    output = call_operation
    expect_success(output)
    output
  end

  def last_operation
    operations.last || call_operation
  end

  def expect_operation_to
    expect { output }.to yield
  end

  def expect_success(obj = output)
    expect(obj.error).to eq(nil)
    expect(obj.errors).to eq({}) if obj.errors
    expect(obj).to be_success
  end

  def expect_failure(obj = output)
    raise 'failed without error' if obj.failure? && obj.error.nil? && obj.errors.blank?
    expect(obj).not_to be_success
  end

  # expect_error('blah')
  # expect_error(/blah/)
  # expect_error(/blah/).not_to eq('blah')
  # expect_error.to include("blah")
  def expect_error(error = nil)
    expect_failure

    expectation = expect(output.error)

    if error
      expectation.to eq(error)
    else
      expectation
    end
  end
end