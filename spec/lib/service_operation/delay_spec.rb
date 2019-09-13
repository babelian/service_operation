require 'spec_helper'

# ServiceOperation
module ServiceOperation
  describe Delay do
    let(:input) do
      { value: 1, id: 1 }
    end

    let(:described_class) do
      Class.new do
        include Delay

        def self.call(input)
          OpenStruct.new(input)
        end
      end
    end

    let(:described_class_with_delay) do
      Class.new(described_class) do
        def self.delay
          self
        end
      end
    end

    describe '.queue' do
      before do
        allow(described_class).to receive(:call).and_call_original
      end

      context 'when the class responds to delay' do
        before do
          allow(described_class).to receive(:delay).and_return(described_class)
        end

        it 'returns the delay objects id' do
          expect(described_class.queue(input)).to eq input[:id]
        end
      end

      context ' when the class does not respond to delay' do
        it 'returns nil' do
          expect(described_class.queue(input)).to be_nil
        end
      end

      after do
        expect(described_class).to have_received(:call).with(input)
      end
    end
  end
end