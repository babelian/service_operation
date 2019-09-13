require 'spec_helper'

require 'service_operation/params/types'

# rubocop:disable Style/CaseEquality
module ServiceOperation::Params
  describe Bool do
    it 'matches true and false' do
      is_expected.to be === true
      is_expected.to be === false
    end

    it 'does not match nil or other values' do
      is_expected.not_to be_nil
      is_expected.not_to be === 5
    end
  end

  describe Any do
    subject { described_class.new([Integer, String]) }

    it 'matches any of the subvalidators' do
      is_expected.to be === 5
      is_expected.to be === 'hello'
    end

    it 'does not match anything else' do
      is_expected.not_to be_nil
      is_expected.not_to be === [1, 2, 3]
    end

    it 'is frozen' do
      is_expected.to be_frozen
    end
  end

  describe EnumerableOf do
    subject { described_class.new(Integer) }

    it '#type' do
      expect(subject.type).to eq(Enumerable)
    end
  end

  describe ArrayOf do
    subject { described_class.new(Integer) }

    it 'ArrayOf(Integer) does not use Any' do
      subject = described_class.new(Integer)
      expect(subject.element_type).to eq Integer
      expect(subject.name).to eq 'ArrayOf(Integer)'
    end

    it 'ArrayOf(String, Integer) uses Any' do
      subject = described_class.new(String, Integer)
      expect(subject.element_type).to be_a(Any)
      expect(subject.name).to eq 'ArrayOf(Any(String, Integer))'
    end

    it 'uses the subvalidator for each element in the array' do
      is_expected.to be === [1, 2, 3]
      is_expected.to be === []
    end

    it 'does not match anything else' do
      is_expected.not_to be_nil
      is_expected.not_to be === 'hello'
      is_expected.not_to be === [:'1', :'2', :'3']
      is_expected.not_to be === Set.new([1, 2, 3])
    end

    it 'is frozen' do
      is_expected.to be_frozen
    end
  end
end

# rubocop:enable Style/CaseEquality