module Bogo
  class Stack
    # Context for the stack execution
    class Context
      include MonitorMixin

      # @return [Array<Stack>] list of stacks associated to context
      attr_reader :stacks

      # Create a new context
      #
      # @param stack [Stack] initial stack associated to this context
      # @return [Stack]
      def initialize(*args, stack:)
        super()
        if !stack.is_a?(Stack)
          raise TypeError,
            "Expecting `#{Stack.name}` but received `#{stack.class.name}`"
        end
        @stacks = [stack].freeze
        @data = Smash.new
        @failures = []
        @recovery_failures = []
        freeze_data!
      end

      # @return [Boolean] stack recovery execution failed
      def recovery_failed?
        synchronize { !@recovery_failures.empty? }
      end

      # Add stack recovery execution failure
      #
      # @param [Action] src action that failed
      # @param [Exception] err resultant exception
      def recovery_failure(src, err)
        synchronize do
          @recovery_failures << [src, err]
        end
      end

      # @return [Boolean] stack execution failed
      def failed?
        synchronize { !@failures.empty? }
      end

      # @raises [Error::StackFailed] raise exception if stack failed
      def failed!
        raise Error::StackFailure, @failures if failed?
      end

      # Add stack execution failure
      #
      # @param [Action] src action that failed
      # @param [Exception] err resultant exception
      def failure(src, err)
        synchronize do
          @failures << [src, err]
        end
      end

      # Associate stack with this context
      #
      # @param stack [Stack]
      # @return [self]
      def for(stack)
        @stacks = @stacks.dup.push(stack).freeze
        self
      end

      # Check if value is set.
      #
      # @return [Boolean]
      def is_set?(*key)
        synchronize do
          val = @data.get(*key)
          return false if val.nil?
          return false if val.is_a?(MonitorMixin::ConditionVariable)
          true
        end
      end

      # Fetch stored value from key location. If value
      # is not set, will wait until value is available.
      #
      # @param key [String, Symbol] path to value location
      # @return [Object]
      def get(*key)
        synchronize do
          val = @data.get(*key)
          return val if !val.nil?
          val = new_cond
          set(*key, val)
          val.wait
          @data.get(*key)
        end
      end

      # Fetch stored value from key location. if value
      # is not set, will return nil immediately
      #
      # @param key [String, Symbol] path to value location
      # @return [Object, nil]
      def grab(*key)
        synchronize do
          @data.get(*key)
        end
      end

      # Store value at key location
      #
      # @param key [String, Symbol] path to value location
      # @param value [Object] value to store
      # @return [Object] value
      def set(*key, value)
        synchronize do
          return delete(*key) if
            value.nil? && !@data.get(*key).is_a?(MonitorMixin::ConditionVariable)

          e_val = @data.get(*key)
          new_data = @data.to_smash
          new_data.set(*key, value)
          @data = new_data.to_smash(:freeze).freeze
          if e_val.is_a?(MonitorMixin::ConditionVariable)
            e_val.broadcast
          end
          value
        end
      end

      # Delete the key from the path
      #
      # @param path [String, Symbol] path to Hash
      # @param key [String, Symbol] key to delete
      # @return [Object, nil] removed value
      def delete(*path, key)
        synchronize do
          e_val = @data.get(*path, key)
          return if e_val.nil? || e_val.is_a?(MonitorMixin::ConditionVariable)
          new_data = @data.to_smash
          base = new_data.get(*path)
          base.delete(key)
          @data = new_data.to_smash(:freeze).freeze
          e_val
        end
      end

      protected

      # Freeze the underlying data
      def freeze_data!
        @data = @data.to_smash(:freeze).freeze
      end
    end
  end
end
