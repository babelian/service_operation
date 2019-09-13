# rubocop:disable Style/RescueModifier
require 'spec_helper'

module ServiceOperation
  describe Context do
    let(:context) { Context.build }

    describe '.build' do
      it 'converts the given hash to a context' do
        context = Context.build(foo: 'bar')

        expect(context).to be_a Context
        expect(context.foo).to eq 'bar'
      end

      it 'builds an empty context if no hash is given' do
        context = Context.build

        expect(context).to be_a(Context)
        expect(context.send(:table)).to eq({})
      end

      it 'doesn not affect the original hash' do
        hash = { foo: 'bar' }
        context = Context.build(hash)

        expect(context).to be_a(Context)
        expect { context.foo = 'baz' }.not_to(change { hash[:foo] })
      end

      it 'preserves an already built context' do
        context1 = Context.build(foo: 'bar')
        context2 = Context.build(context1)

        expect(context2).to be_a(Context)
        expect { context2.foo = 'baz' }.to change { context1.foo }.from('bar').to('baz')
      end
    end

    describe '#success?' do
      let(:context) { Context.build }

      it 'is true by default' do
        expect(context.success?).to eq(true)
      end
    end

    describe '#as_json' do
      let(:args) do
        { arg: 1 }
      end

      let(:hash) do
        hash = context.to_h.merge(changed: true)
        allow(hash).to receive(:as_json).with(args).and_return(hash)
        hash
      end

      it 'converts to hash then delegates to avoid stack loop issue with OpenStructs' do
        context.ok = 1
        allow(context).to receive(:to_h).and_return(hash)
        expect(context.as_json(args)).to eq(hash)
      end
    end

    describe '#fail!' do
      let(:context) { Context.build(foo: 'bar') }

      it 'sets success to false' do
        expect do
          context.fail! rescue nil
        end.to change(context, :success?).from(true).to(false)
      end

      it 'sets failure to true' do
        expect do
          context.fail! rescue nil
        end.to change(context, :failure?).from(false).to(true)
      end

      it 'preserves failure' do
        context.fail! rescue nil

        expect do
          context.fail! rescue nil
        end.not_to change(context, :failure?)
      end

      it 'preserves the context' do
        expect do
          context.fail! rescue nil
        end.not_to change(context, :foo)
      end

      it 'updates the context' do
        expect do
          context.fail!(foo: 'baz') rescue nil
        end.to change(context, :foo).from('bar').to('baz')
      end

      it 'updates the context with a string key' do
        expect do
          context.fail!('foo' => 'baz') rescue nil
        end.to change(context, :foo).from('bar').to('baz')
      end

      it 'raises failure' do
        expect { context.fail! }.to raise_error(Failure)
      end

      it 'makes the context available from the failure' do
        context.fail!
      rescue Failure => error
        expect(error.context).to eq(context)
      end
    end

    describe '#failure? / #success?' do
      it 'is false by default' do
        expect(context.failure?).to be false
      end

      it 'success is true by default' do
        expect(context.success?).to be true
      end
    end

    describe '#coerce_if' do
      let(:expected_value) { 'coerced 1' }

      it 'converts any matching class' do
        context.field = 1
        value = context.coerce_if(:field, Integer, String) { |v| "coerced #{v}" }
        expect(value).to eq expected_value
        expect(context.field).to eq expected_value
      end

      describe 'using parent method name as key' do
        it 'converts' do
          context.enclosing_method_with_block = 1
          expect(enclosing_method_with_block).to eq expected_value
          expect(context.enclosing_method_with_block).to eq expected_value
        end

        def enclosing_method_with_block
          context.coerce_if(Integer) { |value| "coerced #{value}" }
        end
      end
    end

    describe '#fetch' do
      it 'does not set value if it exists' do
        context.something = 1
        expect(context.fetch(:something, 2)).to eq(1)
        expect(context.something).to eq(1)
      end

      it 'sets if nil' do
        expect(context.fetch(:something, 2)).to eq(2)
        expect(context.something).to eq(2)
      end

      it 'can take a block' do
        expect(
          context.fetch(:something) { 1 }
        ).to eq(1)
        expect(context.something).to eq(1)
      end

      it 'prefers block over value' do
        expect(
          context.fetch(:something, 2) { 3 }
        ).to eq(3)
        expect(context.something).to eq(3)
      end

      it 'does not process a block more than once' do
        object = '1'
        allow(object).to receive(:to_i).and_call_original
        2.times { expect(context.fetch(:something) { object.to_i }).to eq(1) }
        expect(object).to have_received(:to_i).once
      end

      context 'block raises an error' do
        it 'writes error.context to the field before re-raising, unless it has already been used' do
          expect do
            context.fetch(:something) do
              raise(
                ServiceOperation::Failure, ServiceOperation::Context.new(value: 1)
              )
            end
          end.to raise_error(Failure)

          expect(context.something.value).to eq(1)

          expect do
            context.fetch(:something_else) { raise(ServiceOperation::Failure, context.something) }
          end.to raise_error(Failure)
        end

        it 'does not write error.context if it is the same context' do
          expect do
            context.fetch(:something) { raise(ServiceOperation::Failure, context) }
          end.to raise_error(Failure)

          expect(context.something).to be nil
        end

        it 'does not write anything to the field if the error does not respond to context' do
          expect do
            context.fetch(:something) { raise('standard') }
          end.to raise_error('standard')

          expect(context.something).to be_nil
        end
      end

      describe 'using parent method name as key' do
        it 'will use the encosing method name if none is passed' do
          expect(enclosing_method_with_value).to eq 'enclosed value'
          expect(context.enclosing_method_with_value).to eq 'enclosed value'
        end

        it 'will use the encosing method name if none is passed with a block' do
          expect(enclosing_method_with_block).to eq 'enclosed block'
          expect(context.enclosing_method_with_block).to eq 'enclosed block'
        end

        def enclosing_method_with_value
          context.fetch 'enclosed value'
        end

        def enclosing_method_with_block
          context.fetch { 'enclosed block' }
        end
      end
    end

    describe '#to_h' do
      let(:params) do
        { a: 1, b: 2, c:3 }
      end

      let(:context) { described_class.new(params) }

      it 'no args' do
        expect(context.to_h).to eq(params)
      end

      it '(:a, :c)' do
        expect(context.to_h(:a,:c)).to eq(params.slice(:a,:c))
      end
    end
  end
end
# rubocop:enable Style/RescueModifier