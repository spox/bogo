module Bogo
  class Stepper
    # Container for callable to execute
    class Callable
      # Callable stub for creating a simple
      # callable from a block
      class Stub < Callable
        def initialize(&block)
          @callable = block
        end

        # @return [String] callable identifier
        def identifier
          self.class.name + "[#{@callable.source_location.join('@')}]"
        end

        protected

        def execute_call(ctx)
          @callable.call(ctx)
        end
      end

      include MonitorMixin

      def initialize
        @called = false
        @cleaned = false
        @cleanups = Set.new
      end

      # @return [String] callable identifier
      def identifier
        self.class.name
      end

      # Call this callable
      #
      # @param [Context] ctx Stepper context
      def call(ctx)
        synchronize do
          raise CallableExecutedError if @called

          @called = true
          execute_call(ctx)
        end

        self
      end

      # @return [Boolean] has been called
      def called?
        synchronize { @called }
      end

      # @return [Boolean] has been cleaned
      def cleaned?
        synchronize { @cleaned }
      end

      # Set a cleanup block to be executed
      # if an error is encountered
      #
      # @param [Context] ctx Stepper context
      # @return [self]
      def cleanup(ctx)
        synchronize do
          raise CallableCleanedError if @cleaned

          @cleaned = true
          @cleanups.each do |callable|
            callable.call(ctx)
          end
          execute_cleanup(ctx)
        end

        self
      end

      # Add a cleanup callable to execute on
      #
      def add_cleanup(callable:, &block)
        callable = Callable::Stub.new(&block) if callable.nil? && block_given?
        raise TypeError,
          "Expecting Callable or block but received #{callable.class}" unless callable.is_a?(Callable)

        @cleanups << callable

        self
      end

      protected

      def execute_cleanup(ctx)
      end

      def execute_call(ctx)
        raise NotImplementedError
      end
    end
  end
end
