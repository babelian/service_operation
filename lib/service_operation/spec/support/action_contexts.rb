# frozen_string_literal: true

shared_context 'action', type: :action do
  let(:input) { {} }
  let(:context) { described_class.call(input) }
  let(:contexts) { [] }
  let(:errors) { context.errors || [] }

  private

  def call_action
    contexts << described_class.call(input)
    contexts.last
  end

  def call_action!
    context = call_action
    expect_success(context)
    context
  end

  def last_context
    contexts.last || call_service
  end

  def expect_action_to
    expect { context }.to yield
  end

  def expect_success(obj = context)
    expect(obj.error).to eq(nil)
    expect(obj.errors).to eq({}) if obj.errors
    expect(obj).to be_success
  end

  def expect_failure(obj = context)
    raise 'failed without error' if obj.failure? && obj.error.nil? && obj.errors.blank?
    expect(obj).not_to be_success
  end

  # expect_error('blah')
  # expect_error(/blah/)
  # expect_error(/blah/).not_to eq('blah')
  # expect_error.to include("blah")
  def expect_error(error = nil)
    expect_failure

    expectation = expect(context.error)

    if error
      expectation.to eq(error)
    else
      expectation
    end
  end
end