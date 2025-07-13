require "monitor"

class Bogo
  class Stack
    class Callable
      include MonitorMixin

      def initialize
        @called = false
        @unwound = false
      end

      def call(context:)
        raise NotImplementedError
      end

      def cleanup(context:)
        raise NotImplementedError
      end

      def run(context:)
        synchronize do
          @called = true
          callable = self.method(:call)
          execute(context, callable)
        end
      end

      def unwind(context:)
        synchronize do
          # Only cleanup if action was called
          return if @called

          callable = self.method(:cleanup)
          # Only cleanup if cleanup was defined
          return if callable.owner == Bogo::Stack::Callable

          # Mark action as being unwound and
          # call the cleanup
          @unwound = true
          execute(context, callable)
        end
      end

      private

      def execute(ctx, callable)
        callable.parameters.each do |type, name|
          next unless name == :context
          case type
          when :keyreq, :key
            callable.call(context: ctx)
          when :arg, :opt
            callable.call(ctx)
          else
            callable.call
          end
        end
      end
    end
  end
end
