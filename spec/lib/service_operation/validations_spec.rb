require 'spec_helper'

module ServiceOperation
  describe Validations do
    subject { operation.new }

    describe '#require_at_least_one_of :param' do
      let(:operation) do
        Class.new do
          include ServiceOperation::Validations

          attr_accessor :param1, :param2

          def call
            require_at_least_one_of :param1, :param2
          end

          def errors
            @errors ||= ServiceOperation::Errors.new
          end
        end
      end

      it 'adds error when missing' do
        subject.call
        expect(subject.errors[:base]).to eq ['One of param1, param2 required.']
        expect(subject.errors[:base].first).to be_frozen
      end

      it 'does not add an error when one of the params is set' do
        subject.param1 = true
        subject.call
        expect(subject.errors).to be_empty
      end
    end
  end
end
