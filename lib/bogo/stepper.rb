require "set"
require "monitor"

module Bogo
  class Stepper
    autoload :Builder, "bogo/stepper/builder"
    autoload :Callable, "bogo/stepper/callable"
    autoload :Context, "bogo/stepper/context"
    autoload :Error, "bogo/stepper/error"
    autoload :Step, "bogo/stepper/step"

    class Stepper < Callable
      include MonitorMixin

      # @return [Context] stepper context
      attr_reader :context
      attr_reader :steps

      def initialize
        @threads = []
        @steps = Set.new
        @context = nil
      end

      # Add a step to the stepper
      #
      # @param [Step] step step to add to stepper
      # @return [self]
      def add(step)
        synchronize do
          raise Error::StepperExecutedError if called?

          steps.add(step)
        end

        self
      end

      # Find step by name or ID
      #
      # @param [String] name_or_id name or ID of step
      # @return [Step]
      def find(name_or_id)
        found = steps.find_all do |step|
          step.name.to_s == name_or_id.to_s ||
            step.id.to_s == name_or_id.to_s
        end

        raise Error::MutipleStepsError if found.size > 1
        raise Error::StepNotFoundError if found.empty?

        found.first
      end

      # Start execution of registered steps
      #
      # @return [Context] stepper context
      def start!
        Context.new.tap { call(ctx) }
      end

      # @return [Boolean] stepper is complete
      def complete?
        @threads.none?(&:alive?)
      end

      # @return [Boolean] stepper is in progress
      def in_progress
        @threads.any?(&:alive?)
      end

      # Wait for all stepper threads to complete
      #
      # @return [self]
      def wait_for_complete
        @threads.each(&:join)

        self
      end

      protected

      def execute_call(ctx)
        @context = ctx

        @threads = steps.map do |step|
          Thread.new { step.call(ctx) }
        end
      end

      def execute_cleanup(ctx)
        steps.each { |step| step.cleanup(ctx) }
      end
    end
  end
end

# def start
#   stepper do
#     step(:import, Import)
#     step(:start, Start, depends_on: :import)
#     step(:provision, Provision, depends_on: :start) do |s|
#       step(:thing, Thing)
#       step(:fubar, Fubar)
#     end
#   end
# end
