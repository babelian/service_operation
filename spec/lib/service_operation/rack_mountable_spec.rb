require 'spec_helper'

# ServiceOperation
module ServiceOperation
  describe RackMountable do
    describe '.call' do
      it 'does not break base_call' do
        output = described_class.call(ok: 1)
        expect(output.ok).to eq(1)
      end
    end

    it 'pending rack specs'
  end
end