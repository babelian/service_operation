require 'spec_helper'

module ServiceOperation
  describe Params do
    # Test Class
    class TestBase
      include Params

      def self.before(*args)
        @before ||= []
        @before += args
      end

      def self.after(*args)
        @after ||= []
        @after += args
      end
    end

    class TestOperation < TestBase
      include Params

      params do
        param1 String   # test de-duping
        param1 Integer  # typed but no coercion
        param2 :integer # typed with coercion
        param3 :string
      end

      returns do
        return1 :string # test de-duping
        return1 :integer
        return_from_method
        return_from_method_optional optional: true
      end

      input do
        input1 optional: true
      end

      output do
        output1 optional: true
      end

      def context
        @context ||= Context.new
      end

      def errors
        @errors ||= Errors.new
      end

      private

      def return_from_method
        context.fetch { 'value' }
      end

      def return_from_method_optional
        context.fetch { 'optional value' }
      end
    end

    subject { TestOperation }

    let(:params) { subject.params }
    let(:returns) { subject.returns }
    let(:instance) { subject.new }
    let(:context) { instance.context }

    #
    # Class Methods
    #

    describe '.params' do
      it 'contains attributes created via .params and .input' do
        expect(params.map(&:name)).to eq [:param1, :param2, :param3, :input1]
      end

      it 'does not allow duplicates' do
        attrs = subject.attributes.select { |a| a.name == :param1 }
        expect(attrs.length).to eq 1
        expect(attrs.first.validator).to eq Integer
      end
    end

    describe '.returns' do
      it 'contains attributes created via .returns and .output' do
        expect(returns.map(&:name)).to eq [
          :return1,
          :return_from_method, :return_from_method_optional,
          :output1
        ]
      end

      it 'does not allow duplicates' do
        attrs = TestOperation.attributes.select { |a| a.name == :return1 }
        expect(attrs.length).to eq 1
        expect(attrs.first.validator).to eq Integer
      end
    end

    it '.remove_params' do
      klass = Class.new(TestBase) do
        params do
          param1
          param2
          param3
        end
      end

      klass.remove_params :param1, :param3
      expect(klass.params.map(&:name)).to eq [:param2]
    end

    it 'defines hooks' do
      expect(subject.before).to eq [:validate_params]
    end

    describe '#validate_params' do
      let(:errors) { instance.errors }

      it 'no coercion and error' do
        context[:param1] = '1'
        expect_validate_to_fail(:params)
        expect(context[:param1]).to eq('1')
        expect(errors[:param1]).to eq ["must be typecast 'Integer'"]
      end

      it 'coercion and no error' do
        context[:param2] = '1'
        expect_validate_to_fail(:params)
        expect(context[:param2]).to eq(1)
        expect(errors[:param2]).to be_nil
      end
    end

    #
    # Instance Methods
    #

    it 'require_at_least_one_of'

    describe '#validate_returns' do
      let(:errors) { instance.errors }

      it 'no coercion and error' do
        context[:return1] = '1'
        expect_validate_to_fail(:returns)
        expect(context[:return1]).to eq('1')
        expect(errors[:return1]).to eq ["must be typecast 'Integer'"]
      end

      it 'no error when valid type' do
        context[:return1] = 1
        expect_validate_to_pass(:returns)
        expect(context[:return1]).to eq(1)
        expect(errors[:return1]).to be_nil
      end

      it 'lazy evaluates if a method exists' do
        expect_validate_to_fail(:returns) # errors on other params
        expect(context[:return_from_method]).not_to be_nil
      end

      it 'does not lazy evaluate if the attribute is optional' do
        expect_validate_to_fail(:returns) # errors on other params
        expect(context[:return_from_method_optional]).to be_nil
      end
    end

    describe '#method_missing' do
      it 'delegates to context if attributes is defined in .params' do
        context[:param1] = 1
        expect(instance.param1).to eq 1
      end

      it 'delegates to context if attribute is defined in .returns' do
        context[:return1] = 1
        expect(instance.return1).to eq 1
      end

      it 'strips ? from method_name when checking attribute names' do
        context[:param1] = 1
        expect(instance.param1?).to eq 1
      end

      it 'raises if attribute is not defined' do
        expect { instance.unknown }.to raise_error(NoMethodError)
      end
    end

    #
    # Inheritance
    #

    describe 'inheritance' do
      # InheritedOperation
      class InheritedOperation < TestOperation
        input do
          input2
        end
        output do
          output2
        end
      end

      subject { InheritedOperation }

      it '.params contains attributes defined in both classes' do
        expect(params.map(&:name)).to eq [:param1, :param2, :param3, :input1, :input2]
      end

      it '.returns contains attributes created via .returns and .output' do
        expect(returns.map(&:name)).to eq [
          :return1, :return_from_method, :return_from_method_optional,
          :output1, :output2
        ]
      end

      it 'defines hooks does not duplicate (actual inheritance taken care of in Hooks)' do
        expect(subject.before).to eq [:validate_params]
      end
    end

    private

    def expect_validate_to_fail(type)
      expect { instance.send("validate_#{type}") }.to raise_error(Failure)
    end

    def expect_validate_to_pass(type)
      instance.send("validate_#{type}")
    end
  end
end