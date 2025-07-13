require "monitor"

module Bogo
  class Stack
    autoload :Action, "bogo/stack/action"
    autoload :Context, "bogo/stack/context"
    autoload :Entry, "bogo/stack/entry"
    autoload :Error, "bogo/stack/error"
    autoload :Hooks, "bogo/stack/hooks"

    include MonitorMixin

    # @return [Array<Action>] list of actions in the stack
    attr_reader :actions
    # @return [Context] context for the stack
    attr_reader :context
    # @return [Hooks] hooks for stack
    attr_reader :hooks
    # @return [Boolean] actions run in parallel
    attr_reader :parallel

    # Create a new stack
    #
    # @return [Stack]
    def initialize
      super
      @actions = [].freeze
      @prepared = false
      @context = Context.new(stack: self)
      @hooks = Hooks.new(stack: self)
      @started = false
      @parallel = false
    end

    # Enable parallel execution of stack actions
    #
    # @return [self]
    def parallelize!
      synchronize do
        be_unprepared!
        @parallel = true
      end
    end

    # @return [Boolean] parallel execution enabled
    def parallel?
      @parallel
    end

    # Push a new callable action onto the end of the stack
    #
    # @param callable [Class, Proc] object that responds to #call or
    #        class with #call instance method
    # @return [Action] generated Action instance
    def push(callable=nil, &block)
      synchronize do
        be_unprepared!
        act = Action.new(stack: self, callable: callable, &block)
        @actions = (actions + [act]).freeze
        act
      end
    end

    # Unshift a new callable action onto the start of the stack
    #
    # @param callable [Class, Proc] object that responds to #call or
    #        class with #call instance method
    # @return [Action] generated Action instance
    def unshift(callable=nil, &block)
      synchronize do
        be_unprepared!
        act = Action.new(stack: self, callable: callable, &block)
        @actions = ([act] + actions).freeze
        act
      end
    end

    # Remove item from the stack
    #
    # @param idx [Integer, Action] index or Action of Action to remove
    # @yield [Array<Action>] stack content is provided to block
    # @yieldreturn [Integer, Action] index or Action of Action to remove
    # @return [Action, NilClass] removed entry
    def remove(idx=nil)
      synchronize do
        be_unprepared!
        idx = yield stack if idx.nil? && block_given?
        if !idx.is_a?(Integer) && !idx.is_a?(Action)
          raise ArgumentError,
            "Expecting `Integer` or `#{Action.name}` but received `#{idx.class}`"
        end
        @actions = actions.dup
        entry = idx.is_a?(Integer) ? @actions.delete_at(idx) : @actions.delete(idx)
        @actions.freeze
        entry
      end
    end

    # Insert item into stack at given index
    #
    # @param at [Integer] index to add item
    # @param callable [Class, Proc] object that responds to #call or
    #        class with #call instance method
    # @param adjust [Integer] adjust index point
    # @return [self]
    def insert(at:, callable:, adjust: 0)
      synchronize do
        be_unprepared!
        idx = yield stack if idx.nil? && block_given?
        if !idx.is_a?(Integer) && !idx.is_a?(Action)
          raise ArgumentError,
            "Expecting `Integer` or `#{Action.name}` but received `#{idx.class.name}`"
        end
        callable = Action.new(stack: self, callable: callable) if
          !callable.is_a?(Action)
        @actions = actions.dup
        @actions.insert(idx + adjust, callable)
        @actions.freeze
      end
      self
    end
    alias_method :insert_at, :insert

    # Insert item before given index
    #
    # @param idx [Integer] index to add item before
    # @param callable [Class, Proc] object that responds to #call or
    #        class with #call instance method
    # @yieldblock callable item
    # @return [self]
    def insert_before(idx: nil, callable: nil, &block)
      insert(idx: idx, callable: callable, adjust: 1, &block)
    end

    # Insert item after given index
    #
    # @param idx [Integer] index to add item after
    # @param callable [Class, Proc] object that responds to #call or
    #        class with #call instance method
    # @yieldblock callable item
    # @return [self]
    def insert_after(idx: nil, callable: nil, &block)
      insert(idx: idx, callable: callable, adjust: -1, &block)
    end

    # Remove last action from the stack
    #
    # @return [Action, nil]
    def pop
      synchronize do
        be_unprepared!
        actions = @actions.dup
        action = actions.pop
        actions.freeze
        @actions = actions
        action
      end
    end

    # Remove first action from the stack
    #
    # @return [Action, nil]
    def shift
      synchronize do
        be_unprepared!
        actions = @actions.dup
        action = actions.shift
        actions.freeze
        @actions = actions
        action
      end
    end

    # @return [Integer] number of actions in stack
    def size
      actions.size
    end

    # @return [TrueClass, FalseClass] stack has started execution
    def started?
      @started
    end

    # @return [TrueClass, FalseClass] stack is prepared for execution
    def prepared?
      @prepared
    end

    # @return [TrueClass, FalseClass] stack has completed execution
    def complete?
      @complete
    end

    # @return [TrueClass, FalseClass] stack execution failed
    def failed?
      complete? && @context.failed?
    end

    # @raises [Error::StackFailed] raise exception if stack failed
    def failed!
      complete? && @context.failed!
    end

    # @return [TrueClass, FalseClass] stack failed but still running
    def failing?
      @context.failed? && !complete?
    end

    # Prepare the stack to be called
    #
    # @return [self]
    def prepare
      synchronize do
        be_unprepared!
        actions = hooks.apply!
        actions.freeze
        actions.each(&:prepare)
        @actions = actions
        @prepared = true
      end
      self
    end

    # Execute the next action in the stack
    #
    # @param ctx [Context] start with given context
    def call(context: nil)
      synchronize do
        be_prepared!
        # Use custom context if provided
        if context
          be_unstarted!
          @context = context.for(self)
        end

        # Mark stack as started
        @started = true

        # If stack has been parallelized start every
        # action within a new thread, otherise execute
        # each action serially
        if @parallel
          @actions.map { |action|
            Thread.new { action.call(context: @context) }
          }.map(&:join)
        else
          @actions.each do |action|
            action.call(context: @context)
          end
        end

        # Check if a failure was encountered during
        # the execution and submit recovery
        execute_recovery! if @context.failed?

        # Mark stack as complete
        @complete = true
      end

      nil
    end

    protected

    # Executes any recoveries defined on
    # registered actions
    def execute_recovery!
      @actions.map do |action|
        action.recover(context: @context)
      end
    end

    def be_unstarted!
      raise Error::StartedError,
        "Stack is already started and cannot be modified" if
        started?
    end

    def be_unprepared!
      raise Error::PreparedError,
        "Stack is already prepared and cannot be modified" if
        prepared?
    end

    def be_prepared!
      raise Error::UnpreparedError,
        "Stack must first be prepared" unless
        prepared?
    end
  end
end
