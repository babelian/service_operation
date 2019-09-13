
require 'spec_helper'

describe ServiceOperation::Failure do
  it 'can add a context' do
    failure = described_class.new 'context'
    expect(failure.context).to eq 'context'
  end
end