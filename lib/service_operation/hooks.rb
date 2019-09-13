# frozen_string_literal: true

module ServiceOperation
  # Simple hooks mechanism with inheritance.
  module Hooks
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    # Hook Methods
    module ClassMethods
      # @example
      #   around do |op|
      #     result = nil
      #     ms = Benchmark.ms { result = op.call }
      #     puts "#{self.class.name} took #{ms}"
      #     result
      #   end
      def around(*hooks, &block)
        add_hooks(:around, hooks, block)
      end

      def before(*hooks, &block)
        add_hooks(:before, hooks, block)
      end

      def after(*hooks, &block)
        add_hooks(:after, hooks, block, :unshift)
      end

      # @return [Array<Symbol, Proc>]
      def around_hooks
        @around_hooks ||= initial_hooks(:around_hooks)
      end

      # @return [Array<Symbol, Proc>]
      def before_hooks
        @before_hooks ||= initial_hooks(:before_hooks)
      end

      # @return [Array<Symbol, Proc>]
      def after_hooks
        @after_hooks ||= initial_hooks(:after_hooks)
      end

      private

      # rubocop:disable Style/SafeNavigation
      def initial_hooks(name)
        superclass && superclass.respond_to?(name) ? superclass.send(name).dup : []
      end
      # rubocop:enable Style/SafeNavigation

      def add_hooks(name, hooks, block, method = :push)
        hooks << block if block
        hooks.each { |hook| send("#{name}_hooks").send(method, hook) }
      end
    end

    private

    def with_hooks
      run_around_hooks do
        run_before_hooks
        yield
        run_after_hooks
      end
    end

    def run_around_hooks(&block)
      self.class.around_hooks.reverse.inject(block) do |chain, hook|
        proc { run_hook(hook, chain) }
      end.call
    end

    def run_before_hooks
      run_hooks(self.class.before_hooks)
    end

    def run_after_hooks
      run_hooks(self.class.after_hooks)
    end

    def run_hooks(hooks)
      hooks.each { |hook| run_hook(hook) }
    end

    # @param [Symbol, Proc] - name of a method defined in the operation or a block
    def run_hook(hook, *args)
      return if hook.class.name =~ /Delayed::Backend/ # prevent a clash with delayed_job gem.

      hook.is_a?(Symbol) ? send(hook, *args) : instance_exec(*args, &hook)
    end

    # unimplemented method from previous project to define "before_call_do_this" style hooks.
    # def run_before_call_methods
    #   private_methods.grep(/^before_call_/).map { |m| send(m) }
    # end
  end
end