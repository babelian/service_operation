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
    # Instance Methods
    #

    it '#errors' do
      expect(instance.errors).to be_a(Errors)
    end

    describe '#fail!' do
      it 'fails if no parameters are passed' do
        expect { instance.fail! }.to raise_error(Failure)
      end

      describe 'error_from_error_code' do
        it 'skips if passed nil' do
          expect { instance.fail!(nil) }.not_to raise_error
        end

        it 'when passed a symbol it looks up in ERRORS' do
          instance.fail!(:test)
          expect_not_to_reach_this_line
        rescue Failure => e
          expect(e.context.errors).to eq(base: ['test error'])
        end

        it 'when passed an unknown symbol it strinifies the error' do
          instance.fail!(:unknown)
          expect_not_to_reach_this_line
        rescue Failure => e
          expect(e.context.errors).to eq(base: ['unknown'])
        end
      end

      it 'when passed an ActiveModel like object'

      it 'merges the errors with the more parameter' do
        instance.fail!('message', more: true)
        expect_not_to_reach_this_line
      rescue Failure => e
        expect(e.context.errors).to eq(base: ['message'])
        expect(e.context.more).to eq true
      end
    end

    describe '#fail_if_errors!' do
      it 'fails when errors' do
        instance.errors[:one] = true
        expect { instance.fail_if_errors! }.to raise_error(Failure)
      end

      it 'does not fail if there are no errors' do
        expect(instance.fail_if_errors!).to eq false
      end
    end

    describe '#valid? / #invalid?' do
      it 'valid' do
        expect(instance).to be_valid
        expect(instance).not_to be_invalid
      end

      it 'invalid' do
        instance.errors[:one] = true
        expect(instance).not_to be_valid
        expect(instance).to be_invalid
      end
    end

    #
    # Method Missing
    #

    describe '#method_missing' do
      let(:object) { OpenStruct.new }
      let(:true_object) { OpenStruct.new('method?' => true) }
      let(:false_object) { OpenStruct.new('method?' => false) }

      describe ErrorHandling::FAIL_IF_UNLESS_REGEXP.inspect do
        {
          'fail_if' => nil,
          'fail_if?' => nil,
          'fail_if!' => ['if', ''],

          'fail_if_persisted?' => nil,
          'fail_if_persisted!' => %w[if persisted],
          'fail_unless_persisted!' => %w[unless persisted],

          'fail_if_multi_word!' => %w[if multi_word]
        }.each do |method_name, match|
          it "#{method_name} -> #{match.inspect}" do
            expect(method_name.scan(ErrorHandling::FAIL_IF_UNLESS_REGEXP).first).to eq match
          end
        end
      end

      describe '#fail_if!(bool, error)' do
        it '(true, error) raises the error' do
          expect { instance.fail_if!(true, :err0r) }.to raise_error(Failure, /err0r/)
        end

        it '(false, :error) does not raise' do
          expect { instance.fail_if!(false, :err0r) }.not_to raise_error
        end
      end

      describe 'fail_if_method!(object)' do
        it 'when object.method? == true it raises' do
          expect { instance.fail_if_method!(true_object) }.to raise_error(Failure)
        end

        it 'when object.method? == false it does not raise' do
          expect { instance.fail_if_method!(false_object) }.not_to raise_error
        end
      end

      describe 'fail_unless_method!(object)' do
        it 'when object.method? == true it does not raise' do
          expect { instance.fail_unless_method!(true_object) }.not_to raise_error
        end

        it 'when object.method? == false it to raise' do
          expect { instance.fail_unless_method!(false_object) }.to raise_error(Failure)
        end
      end

      describe 'fail_if_method!(object, custom_error)' do
        it 'raises with custom error not object.errors' do
          true_object.errors = { base: :no }
          expect { instance.fail_if!(object, :yes) }.to raise_error(Failure, /yes/)
        end
      end

      context '#fail_if_unknown_method!' do
        it 'raises NoMethodError' do
          expect do
            instance.fail_if_unknown_method!(object)
          end.to raise_error(
            NoMethodError, 'OpenStruct does not respond to unknown_method?'
          )
        end
      end
    end

    private

    def expect_not_to_reach_this_line
      value = true
      expect(value).to be false
    end
  end
end