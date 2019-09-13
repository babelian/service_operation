require 'spec_helper'

# ServiceOperation
module ServiceOperation
  describe Hooks do
    describe '#with_hooks' do
      #
      # Around Hooks
      #
      context 'with an around hook method' do
        let(:hooked) do
          build_hooked do
            around :add_around_before_and_around_after

            private

            def add_around_before_and_around_after(hooked)
              steps << :around_before
              hooked.call
              steps << :around_after
            end
          end
        end

        it 'runs the around hook method' do
          expect(hooked.process).to eq [
            :around_before,
            :process,
            :around_after
          ]
        end
      end

      context 'with an around hook block' do
        let(:hooked) do
          build_hooked do
            around do |hooked|
              steps << :around_before
              hooked.call
              steps << :around_after
            end
          end
        end

        it 'runs the around hook block' do
          expect(hooked.process).to eq [
            :around_before,
            :process,
            :around_after
          ]
        end
      end

      context 'with an around hook method and block in one call' do
        let(:hooked) do
          build_hooked do
            around :add_around_before1_and_around_after1 do |hooked|
              steps << :around_before2
              hooked.call
              steps << :around_after2
            end

            private

            def add_around_before1_and_around_after1(hooked)
              steps << :around_before1
              hooked.call
              steps << :around_after1
            end
          end
        end

        it 'runs the around hook method and block in order' do
          expect(hooked.process).to eq [
            :around_before1,
            :around_before2,
            :process,
            :around_after2,
            :around_after1
          ]
        end
      end

      context 'with an around hook method and block in multiple calls' do
        let(:hooked) do
          build_hooked do
            around do |hooked|
              steps << :around_before1
              hooked.call
              steps << :around_after1
            end

            around :add_around_before2_and_around_after2

            private

            def add_around_before2_and_around_after2(hooked)
              steps << :around_before2
              hooked.call
              steps << :around_after2
            end
          end
        end

        it 'runs the around hook block and method in order' do
          expect(hooked.process).to eq [
            :around_before1,
            :around_before2,
            :process,
            :around_after2,
            :around_after1
          ]
        end
      end

      #
      # Before Hooks
      #

      context 'with a before hook method' do
        let(:hooked) do
          build_hooked do
            before :add_before

            private

            def add_before
              steps << :before
            end
          end
        end

        it 'runs the before hook method' do
          expect(hooked.process).to eq [
            :before,
            :process
          ]
        end
      end

      context 'with a before hook block' do
        let(:hooked) do
          build_hooked do
            before do
              steps << :before
            end
          end
        end

        it 'runs the before hook block' do
          expect(hooked.process).to eq [
            :before,
            :process
          ]
        end
      end

      context 'with a before hook method and block in one call' do
        let(:hooked) do
          build_hooked do
            before :add_before1 do
              steps << :before2
            end

            private

            def add_before1
              steps << :before1
            end
          end
        end

        it 'runs the before hook method and block in order' do
          expect(hooked.process).to eq [
            :before1,
            :before2,
            :process
          ]
        end
      end

      context 'with a before hook method and block in multiple calls' do
        let(:hooked) do
          build_hooked do
            before do
              steps << :before1
            end

            before :add_before2

            private

            def add_before2
              steps << :before2
            end
          end
        end

        it 'runs the before hook block and method in order' do
          expect(hooked.process).to eq [
            :before1,
            :before2,
            :process
          ]
        end
      end

      #
      # After Hooks
      #

      context 'with an after hook method' do
        let(:hooked) do
          build_hooked do
            after :add_after

            private

            def add_after
              steps << :after
            end
          end
        end

        it 'runs the after hook method' do
          expect(hooked.process).to eq [
            :process,
            :after
          ]
        end
      end

      context 'with an after hook block' do
        let(:hooked) do
          build_hooked do
            after do
              steps << :after
            end
          end
        end

        it 'runs the after hook block' do
          expect(hooked.process).to eq [
            :process,
            :after
          ]
        end
      end

      context 'with an after hook method and block in one call' do
        let(:hooked) do
          build_hooked do
            after :add_after1 do
              steps << :after2
            end

            private

            def add_after1
              steps << :after1
            end
          end
        end

        it 'runs the after hook method and block in order' do
          expect(hooked.process).to eq [
            :process,
            :after2,
            :after1
          ]
        end
      end

      context 'with an after hook method and block in multiple calls' do
        let(:hooked) do
          build_hooked do
            after do
              steps << :after1
            end

            after :add_after2

            private

            def add_after2
              steps << :after2
            end
          end
        end

        it 'runs the after hook block and method in order' do
          expect(hooked.process).to eq [
            :process,
            :after2,
            :after1
          ]
        end
      end

      #
      # All Hooks
      #

      context 'with around, before and after hooks' do
        let(:hooked) do
          build_hooked do
            around do |hooked|
              steps << :around_before1
              hooked.call
              steps << :around_after1
            end

            around do |hooked|
              steps << :around_before2
              hooked.call
              steps << :around_after2
            end

            before do
              steps << :before1
            end

            before do
              steps << :before2
            end

            after do
              steps << :after1
            end

            after do
              steps << :after2
            end
          end
        end

        it 'runs hooks in the proper order' do
          expect(hooked.process).to eq [
            :around_before1,
            :around_before2,
            :before1,
            :before2,
            :process,
            :after2,
            :after1,
            :around_after2,
            :around_after1
          ]
        end
      end

      #
      # Inheritance
      #

      context 'inheriting hooks from a parent class' do
        context 'around_hooks' do
          let(:hooked) do
            build_hooked do
              around :add_around_before_and_around_after
              around { |hooked| hooked.call }
            end
          end

          let(:inherited) { Class.new(hooked) }

          it 'inherits around hooks from parent class' do
            expect(inherited.around_hooks).to eq(hooked.around_hooks)
          end

          it 'does not add hook to parent class' do
            inherited.class_eval { around(&:call) }
            expect(inherited.around_hooks.size).not_to eq(hooked.around_hooks.size)
          end
        end

        context 'before_hooks' do
          let(:hooked) do
            build_hooked do
              before :add_before
              before {}
            end
          end

          let(:inherited) { Class.new(hooked) }

          it 'inherites before hooks from parent class' do
            expect(inherited.before_hooks).to eq(hooked.before_hooks)
          end

          it 'does not add hook to parent class' do
            inherited.class_eval { before {} }
            expect(inherited.before_hooks).not_to eq(hooked.before_hooks)
          end
        end

        context 'after_hooks' do
          let(:hooked) do
            build_hooked do
              after :add_after
              after {}
            end
          end

          let(:inherited) { Class.new(hooked) }

          it 'inherites after hooks from parent class' do
            expect(inherited.after_hooks).to eq(hooked.after_hooks)
          end

          it 'does not add hook to parent class' do
            inherited.class_eval { after {} }
            expect(inherited.after_hooks).not_to eq(hooked.after_hooks)
          end
        end
      end
    end

    private

    # Helper to build a class with Hooks
    def build_hooked(&block)
      hooked = Class.new do
        include ServiceOperation::Hooks

        attr_reader :steps

        def self.process
          new.tap(&:process).steps
        end

        def initialize
          @steps = []
        end

        def process
          with_hooks { steps << :process }
        end
      end

      hooked.class_eval(&block) if block
      hooked
    end
  end
end