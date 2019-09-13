require 'spec_helper'

require 'service_operation/params/attribute'

module ServiceOperation::Params
  describe Attribute do
    subject { described_class.new(options) }

    let(:options) do
      { name: :whatever, validator: String, custom: 'data' }
    end

    describe '.define' do
      subject { described_class.define(*args) }

      let(:args) do
        [
          :something, Anything,
          default: 'default',
          log: false, optional: true
        ]
      end

      it 'raises an error if a keyword is used' do
        args[0] = ServiceOperation::KEYWORDS.first
        expect { subject }.to raise_error(/keyword/)
      end

      it 'defaults to no coercion' do
        expect(subject.coercer).to be_nil
      end

      it 'converts :bool to Bool' do
        args[1] = :bool
        is_expected.to have_attributes(validator: Bool)
      end

      it 'converts :boolean to Bool' do
        args[1] = :boolean
        is_expected.to have_attributes(validator: Bool)
      end

      it 'converts :string to String and uses default coercion' do
        args[1] = :string
        is_expected.to have_attributes(validator: String)
        expect(subject.coercer).to eq described_class::COERCIONS['String']
      end

      it "converts 'string' into classes and uses default coercion" do
        args[1] = 'string'
        is_expected.to have_attributes(validator: String)
        expect(subject.coercer).to eq described_class::COERCIONS['String']
      end

      it 'converts [:integer] to EnumberableOf(Integer) and uses default coercion' do
        args[1] = [:integer]
        is_expected.to have_attributes(validator: EnumerableOf.new(Integer))
        expect(subject.coercer.call('1')).to eq [1]
      end

      it 'converts [:string, :integer] to an EnumerableOf(Symbol, Integer) and sets coerce: true' do
        args[1] = [:string, :integer]
        is_expected.to have_attributes(validator: EnumerableOf.new(String, Integer))
        expect(subject.coercer).to be true
      end

      it 'when converting it does not override coerce: false' do
        args[1] = :string
        args.last[:coerce] = false
        expect(subject.coercer).to eq false
      end

      it 'sets attributes' do
        attributes = args.last.dup.merge(name: :something, validator: Anything)
        is_expected.to have_attributes(attributes)
      end
    end

    #
    # Instance Methods
    #

    describe '.new' do
      it 'has default attributes' do
        is_expected.to have_attributes(coercer: nil, log: true)
        expect(subject.default).to eq(nil)
      end

      it 'can set misc options' do
        expect(subject.options[:custom]).to eq 'data'
      end
    end

    describe '#from' do
      it 'coercer: nil returns value ' do
        expect(subject.from(1)).to eq(1)
      end

      it 'coercer: true returns value' do
        options[:coercer] = true
        expect(subject.from(1)).to eq(1)
      end

      it 'coercer: proc(&:upcase)' do
        options[:coercer] = proc(&:upcase)
        expect(subject.coercer).to be_a(Proc)
        expect(subject.from('hello')).to eq('HELLO')
      end

      it 'coercer: String.method(:try_convert)' do
        options[:coercer] = String.method(:try_convert)
        expect(subject.from('string')).to eq('string')
        expect(subject.from(1)).to eq(nil)
      end

      it 'coercer: proc(&:to_i), optional: true returns nil for nil' do
        options[:coercer] = proc(&:to_i)
        options[:optional] = true
        expect(subject.from(nil)).to be_nil
      end

      it "coercer: proc(&:to_i), optional: true returns 1 for '1'" do
        options[:coercer] = proc(&:to_i)
        options[:optional] = true
        expect(subject.from('1')).to eq 1
      end

      it 'coercer: proc(&:to_i), returns nil for nil' do
        options[:coercer] = proc(&:to_i)
        expect(subject.from(nil)).to eq nil
      end

      it 'default: true does not override false' do
        options[:default] = true
        expect(subject.from(false)).to eq false
      end
    end

    describe '#error' do
      it 'nil if valid' do
        expect(subject.error('string')).to be_nil
      end

      it "can't be blank" do
        expect(subject.error(nil)).to eq("can't be blank")
      end

      it 'must be typecast' do
        expect(subject.error(1)).to eq("must be typecast 'String'")
      end
    end

    describe '#optional? / #required?' do
      context 'when optional: false' do
        before { options[:optional] = false }
        it { is_expected.not_to be_optional }
        it { is_expected.to be_required }
      end
      context 'when optional: true' do
        before { options[:optional] = true }
        it { is_expected.to be_optional }
        it { is_expected.not_to be_required }
      end
    end

    describe '#validate?' do
      before { options[:validator] = String }

      it 'passes when optional: true and value is nil' do
        options[:optional] = true
        expect(subject.validate?(nil)).to be true
      end

      it 'pass when value is valid type' do
        expect(subject.validate?('string')).to be true
      end

      it 'does not pass when invalid type' do
        expect(subject.validate?(1)).to be false
      end

      it 'special exception nil is not a valid Object' do
        options[:validator] = Object
        expect(subject.validate?(nil)).to be false
        expect(subject.validate?(1)).to be true
      end
    end
  end
end