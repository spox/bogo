module Bogo
  class Stack
    # Actions which are run via the stack
    class Action
      include MonitorMixin

      autoload :Arguments, "bogo/stack/action/arguments"

      # @return [Stack] parent stack
      attr_reader :stack
      # @return [Object] callable
      attr_reader :callable
      # @return [Array<Object>, Arguments] arguments for callable
      attr_reader :arguments
      # @return [Proc] recovery block
      attr_reader :recovery

      # Create a new action
      #
      # @param stack [Stack] stack associated with this action
      # @param callable [Object] callable item
      # @return [Action]
      def initialize(stack:, callable: nil, recover: nil, &block)
        super()
        if callable && block
          raise ArgumentError,
            "Expecting callable argument or block, not both"
        end
        c = callable || block
        if c.is_a?(Class)
          if !c.instance_methods.include?(:call)
            raise ArgumentError,
              "Expecting callable but class does not provide `#call'"
          end
        else
          if !c.respond_to?(:call)
            raise ArgumentError,
              "Expecting callable but no callable provided"
          end
        end
        if !stack.is_a?(Stack)
          raise TypeError,
            "Expecting `#{Stack.name}` but received `#{stack.class.name}`"
        end
        if recover && !recover.is_a?(Proc)
          raise TypeError,
            "Expecting Proc but received '#{recover.class}'"
        end
        @stack = stack
        @callable = c
        @recovery = recover
        @called = false
        @arguments = []
      end

      # @return [TrueClass, FalseClass] action has been prepared
      def prepared?
        @arguments.frozen?
      end

      # Arguments to pass to callable
      def with(*args)
        synchronize do
          if @arguments.frozen?
            raise Error::PreparedError,
              "Cannot set arguments after action has been prepared"
          end
          @arguments = args
        end
        self
      end

      # Prepare the action to be called
      def prepare
        synchronize do
          if @arguments.frozen?
            raise Error::PreparedError,
              "Action has already been prepared"
          end
          m = callable
          if callable.is_a?(Class)
            @callable = callable.new
            m = @callable.method(:call)
          end
          if !callable.respond_to?(:call)
            raise ArgumentError,
              "Given callable does not respond to `#call'"
          end
          if m.parameters.any?{ |p| [:key, :keyreq].include?(p.first) && p.last == :context }
            if @arguments.last.is_a?(Hash)
              @arguments.last[:context] = stack.context
            else
              @arguments << {context: stack.context}
            end
          end

          @arguments = Arguments.load(callable: m, arguments: @arguments)

          @callable.freeze
          @arguments.freeze
          if @recovery.nil? && callable.respond_to?(:recover)
            @recovery = callable.method(:recover)
          end
        end

        self
      end

      # @return [Boolean] action has been called
      def called?
        !!@called
      end

      # Set recovery for action.
      #
      # @param [Proc] recover recovery implementaiton
      # @note if set, action recovery will not
      # be called if defined on instance
      def set_recovery(recover: nil, &block)
        recover = block if recover.nil?
        if !recover.is_a?(Proc)
          raise TypeError,
            "Expecting Proc but received '#{recover.class}'"
        end
        @recovery = recover
      end

      # Call the action
      #
      # @param ctx [Context] context data
      def call(context: nil)
        synchronize do
          raise Error::PreparedError,
            "Cannot call action, not prepared" if !arguments.frozen?
          raise Error::CalledError,
            "Action has already been called" if called?
          @called = true
          list = arguments.list
          named = arguments.named
          # If a context was provided, inject it into
          # the named arguments and overwrite set context
          if context && arguments.named.key?(:context)
            named = named.merge(context: context)
          end
          begin
            callable.call(*list, **named)
          rescue => err
            context.failure(self, err)
          end
        end
      end

      # Execute failure recovery if provided
      #
      # @param [Context] context context data
      def recover(context: nil)
        return if recovery.nil?
        begin
          recovery.call(context, arguments)
        rescue => err
          context.recovery_failure(self, err)
        end
      end
    end
  end
end
