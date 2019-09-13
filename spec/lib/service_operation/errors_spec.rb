
require 'spec_helper'

describe ServiceOperation::Errors do
  describe '#add' do
    it 'does not add empties' do
      subject.add(:something)
      expect(subject.key?(:something)).to be false
    end

    it 'adds each error to an array' do
      subject.add(:something, 'error1')
      expect(subject[:something]).to eq %w[error1]

      subject.add(:something, 'error2')
      expect(subject[:something]).to eq %w[error1 error2]
    end

    it 'can add multiple errors' do
      subject.add(:something, 'error1', 'error2')
      expect(subject[:something]).to eq %w[error1 error2]

      subject.add(:something, %w[error3 error4])
      expect(subject[:something]).to eq %w[error1 error2 error3 error4]
    end
  end

  describe '#coerced_merge' do
    {
      'Hash' => [{ error: 'error' }, { error: ['error'] }],
      'StandardError' => [StandardError.new('failure'), { base: ['failure'] }],
      'String' => ['error', { base: ['error'] }]
    }.each do |example, (input, output)|
      it example do
        expect(
          subject.coerced_merge(input).to_h
        ).to eq(output)
      end
    end

    it 'responds_to?(:errors)'
    it 'responds_to?(:messages)'
    it 'array of ActiveModel style objects'
  end
end