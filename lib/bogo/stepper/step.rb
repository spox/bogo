require "monitor"
require "securerandom"
require "set"

module Bogo
  class Stepper
    # Individual step within stepper
    class Step < Callable
      include MonitorMixin

      # @return [String] name of step
      attr_reader :name
      # @return [Symbol] ID of step
      attr_reader :id
      # @return [Set<Callable>] callables to execute before
      attr_reader :befores
      # @return [Set<Callable>] callables to execute after
      attr_reader :afters
      # @return [Set<Step>] dependencies for step
      attr_reader :upstream
      # @return [Set<Step>] dependent for steps
      attr_reader :downstream
      # @return [Callable] callable to execute for step
      attr_reader :callable

      def initialize(name:, id: nil, callable: nil, &block)
        raise TypeError,
          "Expecting String for name but received #{name.class}" unless name.is_a?(String)
        @name = name
        @id = id || SecureRandom.uuid.to_sym
        raise TypeError,
          "Expecting Symbol for id but received #{id.class}" unless id.is_a?(Symbol)
        callable = Callable::Stub.new(&block) if callable.nil? && block_given?
        raise TypeError,
          "Expecting Callable or block but received #{callable.class}" unless callable.is_a?(Callable)

        @callable = callable
        @interrupted = false
        @complete = false
        @failed = false
        @befores = Set.new
        @afters = Set.new
        @upstream = Set.new
        @downstream = Set.new
      end

      # Add a callable to execute before executing
      # callable for this step
      #
      # @param [Callable] callable callable to execute
      # @return [self]
      def before(callable:, &block)
        synchronize do
          raise Error::StepExecutedError if complete?

          callable = Callable::Stub.new(&block) if callable.nil? && block_given?
          raise TypeError,
            "Expecting Callable or block but received #{callable.class}" unless callable.is_a?(Callable)
          befores.add(callable)
        end

        self
      end

      # Add a callable to execute after executing
      # callable for this step
      #
      # @param [Callable] callable callable to execute
      # @return [self]
      def after(callable:, &block)
        synchronize do
          raise Error::StepExecutedError if complete?

          callable = Callable::Stub.new(&block) if callable.nil? && block_given?
          raise TypeError,
            "Expecting Callable or block but received #{callable.class}" unless callable.is_a?(Callable)
          afters.add(callable)
        end

        self
      end

      # Add a step that this step depends on
      #
      # @param [Step] step step this steps depends on
      # @return [self]
      def depends_on(step, set_downstream: true)
        synchronize do
          raise Error::StepExecutedError if complete?

          raise TypeError,
            "Expecting Step but received #{step.class}" unless step.is_a?(Step)
          upstream.add(step)
          step.ancestor_of(self, set_upstream: false) if set_downstream
        end

        self
      end

      # Add a step that requires this step
      #
      # @param [Step] step step that requires this step
      # @return [self]
      def ancestor_of(step, set_upstream: true)
        synchronize do
          raise Error::StepExecutedError if complete?

          raise TypeError,
            "Expecting Step but received #{step.class}" unless step.is_a?(Step)
          downstream.add(step)
          step.depnds_on(self, set_downstream: false) if set_upstream
        end

        self
      end

      # @return [Boolean] step execution successfully completed
      def success?
        @complete
      end

      # @return [Boolean] step execution is complete
      def complete?
        @complete || @failed || @interrupted
      end

      # @return [Boolean] step execution failed
      def failed?
        @failed
      end

      # @return [Boolean] step execution interrupted
      def interrupted?
        @interrupted
      end

      # Attempt to run the step. If dependencies have not
      # completed the step will not run.
      #
      # @param [Context] ctx Context of the stepper
      # @return [Boolean] step execution was started
      def try_run(ctx)
        call(ctx)
      end

      protected

      def execute_call(ctx)
        return false if upstream.any? { |step| !step.complete?  }

        action = catch(:complete) do
          begin
            # Execute any before callables
            befores.each do |callable|
              # If the context reports as halted, stop
              throw :complete, :halt if ctx.halted?

              # Check the result for special value to
              # skip execution
              throw :complete, :skip if callable.call(ctx) == :skip
            end

            # Only continue execution if not halted
            throw :complete, :halt if ct.halted?

            # Execute step
            callable.call(ctx)

            # Execute any after callables
            afters.each do |callable|
              # Halt callbacks if halted
              throw :complete, :halt if ctx.halted?

              callable.call(ctx)
            end
          rescue
            # Mark step as failed
            @failed = true
            # Mark the context as failed
            ctx.failed = true

            raise
          end
        end

        return true if action == :skip || action == :halt

        # Mark step as complete
        @complete = true

        # Attempt to trigger any downstream steps
        downstream.each { |step| step.try_run(ctx) }

        true
      end
    end
  end
end
