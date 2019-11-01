require 'spec_helper'

module ServiceOperation
  describe Base do
    let(:operation) do
      op = Class.new.send(:include, described_class)
      op::ERRORS = { test: 'test error' }.freeze
      op
    end

    let(:instance) { operation.new }

    #
    # ClassMethods
    #

    describe '.call' do
      let(:context) { Context.new }
      let(:instance) { instance_double('Operation', context: context) }

      it 'calls an instance with the given context' do
        allow(operation).to receive(:new).once.with(foo: 'bar') { instance }
        allow(instance).to receive(:run).once.with(no_args)

        expect(operation.call(foo: 'bar')).to eq(context)
        expect(operation).to have_received(:new)
        expect(instance).to have_received(:run)
      end

      it 'provides a blank context if none is given' do
        allow(operation).to receive(:new).once.with({}) { instance }
        allow(instance).to receive(:run).once.with(no_args)

        expect(operation.call).to eq(context)
        expect(operation).to have_received(:new)
        expect(instance).to have_received(:run)
      end
    end

    describe '.call!' do
      let(:context) { instance_double('Context') }
      let(:instance) { instance_double('Operation', context: context) }

      it 'calls an instance with the given context' do
        allow(operation).to receive(:new).once.with(foo: 'bar') { instance }
        allow(instance).to receive(:run!).once.with(no_args)

        expect(operation.call!(foo: 'bar')).to eq(context)
      end

      it 'provides a blank context if none is given' do
        allow(operation).to receive(:new).once.with({}) { instance }
        allow(instance).to receive(:run!).once.with(no_args)

        expect(operation.call!).to eq(context)
      end
    end

    describe '.allow_remote!' do
      it 'defaults to false' do
        expect(operation.allow_remote).to be false
      end

      it 'can be set to true with allow_remote!' do
        operation.allow_remote!
        expect(operation.allow_remote).to be true
      end
    end

    describe '.new' do
      let(:context) { instance_double('Context') }

      it 'initializes a context' do
        allow(Context).to receive(:build).once.with(foo: 'bar') { context }

        instance = operation.new(foo: 'bar')

        expect(instance).to be_a(operation)
        expect(instance.context).to eq(context)
        expect(Context).to have_received(:build)
      end

      it 'initializes a blank context if none is given' do
        allow(Context).to receive(:build).once.with({}) { context }

        instance = operation.new

        expect(instance).to be_a(operation)
        expect(instance.context).to eq(context)
        expect(Context).to have_received(:build)
      end
    end

    #
    # Instance Methods
    #

    describe '#call' do
      it 'exists' do
        expect(instance).to respond_to(:call)
        expect { instance.call }.not_to raise_error
        expect { instance.method(:call) }.not_to raise_error
      end
    end

    describe '#context' do
      let(:operation) do
        operation = Class.new do
          include Base

          def fetched
            context { 'value' } # rubocop:disable all
          end
        end
      end

      it 'returns @context' do
        expect(instance.context).to be_a Context
        expect(instance.context).to eq instance.instance_variable_get('@context')
      end

      it 'caches when an attribute name and block are passed' do
        expect(
          instance.context(:attribute_name) { 1 }
        ).to eq(1)
        expect(instance.context.attribute_name).to eq(1)
      end

      it 'can infer attribute name from enclosing method' do
        expect(instance.fetched).to eq('value')
        expect(instance.context.fetched).to eq('value')
      end
    end

    describe '#run' do
      it 'runs the operation' do
        allow(instance).to receive(:run!).once.with(no_args)

        instance.run

        expect(instance).to have_received(:run!)
      end

      it 'rescues failure' do
        allow(instance).to receive(:run!).and_raise(Failure)

        expect { instance.run }.not_to raise_error

        expect(instance).to have_received(:run!)
      end

      it 'raises other errors' do
        allow(instance).to receive(:run!).and_raise('foo')

        expect { instance.run }.to raise_error('foo')
      end
    end

    describe '#run!' do
      it 'runs hooks and #call' do
        allow(instance).to receive(:call).once.with(no_args)

        instance.run!

        expect(instance).to have_received(:call)
      end

      it 'does not run hooks/#call if there are errors' do
        allow(instance).to receive(:call)
        instance.errors.add(:error, 'some message')
        instance.run
        expect(instance).not_to have_received(:call)
      end

      it 'skips #call if context.skip is set' do
        allow(instance).to receive(:skip).and_return(true)
        allow(instance).to receive(:call)
        expect(instance.run).to be true
        expect(instance).to have_received(:skip)
        expect(instance).not_to have_received(:call)
      end

      it 'raises failure' do
        allow(instance).to receive(:run!).and_raise(Failure)

        expect { instance.run! }.to raise_error(Failure)
      end

      it 'raises other errors' do
        allow(instance).to receive(:run!).and_raise('foo')
        expect { instance.run }.to raise_error('foo')
      end
    end

    describe '#skip / #skip!' do
      it 'delegates to context or returns false, can be set' do
        expect(instance.skip).to be false
        instance.skip!
        expect(instance.skip).to be true
      end
    end
  end
end