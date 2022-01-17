require "monitor"

module Bogo
  # Simple call stack implementation
  class Stack
    class Hooks
      include MonitorMixin

      # @return [Array<Entry>] list of entries to prepend to stack actions
      attr_reader :prepend_entries
      # @return [Array<Entry>] list of entries to append to stack actions
      attr_reader :append_entries
      # @return [Array<Entry>] list of entries to prepend to specific actions
      attr_reader :before_entries
      # @return [Array<Entry>] list of entries to append to specific actions
      attr_reader :after_entries

      # @return [Stack] stack associated with these hooks
      attr_reader :stack

      # Create a new set hooks
      #
      # @param stack [Stack]
      # @return [self]
      def initialize(stack:)
        super()
        if !stack.is_a?(Stack)
          raise TypeError,
            "Expecting `#{Stack.name}` but received `#{stack.class.name}`"
        end
        @prepend_entries = [].freeze
        @append_entries = [].freeze
        @after_entries = [].freeze
        @before_entries = [].freeze
        @applied = false
        @stack = stack
      end

      # Add hook after identifier
      #
      # @param identifier [Symbol, Class, Proc] action to hook after
      # @yieldblock Hook to execute
      # @return [self]
      def after(identifier, &block)
        be_callable!(identifier) unless identifier.is_a?(Symbol)
        be_callable!(block)
        synchronize do
          if applied?
            raise Error::ApplyError,
              "Hooks have already been applied to stack"
          end
          @after_entries = after_entries +
            [Entry.new(identifier: identifier,
            action: Action.new(stack: stack, callable: block))]
          @after_entries.freeze
        end
        self
      end

      # Add hook before identifier
      #
      # @param identifier [Symbol, Class, Proc] action to hook before
      # @yieldblock Hook to execute
      # @return [self]
      def before(identifier, &block)
        be_callable!(identifier) unless identifier.is_a?(Symbol)
        be_callable!(block)
        synchronize do
          if applied?
            raise Error::ApplyError,
              "Hooks have already been applied to stack"
          end
          @before_entries = before_entries +
            [Entry.new(identifier: identifier,
            action: Action.new(stack: stack, callable: block))]
          @before_entries.freeze
        end
        self
      end

      # Add hook before stack actions
      #
      # @yieldblock Hook to execute
      # @return [self]
      def prepend(&block)
        be_callable!(block)
        synchronize do
          if applied?
            raise Error::ApplyError,
              "Hooks have already been applied to stack"
          end
          @prepend_entries = prepend_entries +
            [Action.new(stack: stack, callable: block)]
          @prepend_entries.freeze
        end
        self
      end

      # Add hook after stack actions
      #
      # @yieldblock Hook to execute
      # @return [self]
      def append(&block)
        be_callable!(block)
        synchronize do
          if applied?
            raise Error::ApplyError,
              "Hooks have already been applied to stack"
          end
          @append_entries = append_entries +
            [Action.new(stack: stack, callable: block)]
          @append_entries.freeze
        end
        self
      end

      # @return [Boolean] hooks have been applied to stack
      def applied?
        !!@applied
      end

      # Apply hooks to stack action list
      #
      # @return [Array<Action>] action list with hooks
      def apply!
        synchronize do
          if applied?
            raise Error::ApplyError,
              "Hooks have already been applied to stack"
          end
          actions = stack.actions.dup
          stubs = [:stub] * actions.size
          before_entries.find_all { |e| e.identifier == :all }.each do |entry|
            stubs.count.times.to_a.reverse.each do |i|
              stubs.insert(i, entry.action)
            end
          end
          after_entries.find_all { |e| e.identifier == :all }.each do |entry|
            stubs.count.times.to_a.reverse.each do |i|
              stubs.insert(i + 1, entry.action)
            end
          end
          actions = stubs.map do |item|
            item == :stub ? actions.pop : item
          end
          before_entries.find_all { |e| e.identifier != :all }.each do |entry|
            idx = actions.index { |a| a.callable == entry.identifier }
            next if idx.nil?
            actions.insert(idx, entry.action)
          end
          after_entries.find_all { |e| e.identifier != :all }.each do |entry|
            idx = actions.index { |a| a.callable == entry.identifier }
            next if idx.nil?
            actions.insert(idx + 1, entry.action)
          end
          @applied = true
          actions = prepend_entries + actions + append_entries
        end
      end

      protected

      # Raise exception if given thing is not a callable
      #
      # @param thing [Object]
      # @return [
      def be_callable!(thing)
        return if thing.respond_to?(:call)
        return if thing.is_a?(Class) && thing.instance_methods.include?(:call)
        raise TypeError, "Expecting callable but received `#{thing.class.name}`"
      end
    end

    class Entry
      attr_reader :identifier
      attr_reader :action

      def initialize(identifier:, action:)
        if !action.is_a?(Action)
          raise TypeError, "Expecting `#{Action.name}` but received `#{action.class.name}`"
        end
        @identifier = identifier
        @action = action
      end
    end

    # Stack related errors
    class Error < StandardError
      class PreparedError < Error; end
      class UnpreparedError < Error; end
      class ApplyError < Error; end
      class CalledError < Error; end
      class InvalidArgumentsError < Error; end
    end

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
        freeze_data!
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

    # Actions which are run via the stack
    class Action
      include MonitorMixin

      # Arguments to pass to action when called
      class Arguments
        # @return [Array<Object>] list of arguments
        attr_reader :list
        # @return [Hash<Symbol,Object>] named arguments
        attr_reader :named

        def initialize(list: [], named: {})
          list = [] if list.nil?
          named = {} if named.nil?
          raise TypeError, "Expected Array but received #{list.class.name}" if
            !list.is_a?(Array)
          raise TypeError, "Expecting Hash but received #{named.class.name}" if
            !named.is_a?(Hash)
          @list = list
          @named = Hash[named.map{ |k,v| [k.to_sym, v] }]
        end

        # Generate a new Arguments instance when given an argument
        # list and the method they will be provided to
        #
        # @param callable [Method,Proc] method to call with arguments
        # @param arguments [Array] arguments to call method
        # @return [Arguments]
        def self.load(callable:, arguments:)
          arguments = arguments.dup
          nargs = {}
          # check if we have any named parameters
          if callable.parameters.any?{ |p| [:key, :keyreq].include?(p.first) } && arguments.last.is_a?(Hash)
            p_keys = callable.parameters.map{ |p| p.last if [:key, :keyreq].include?(p.first) }
            e_keys = arguments.last.keys
            if (e_keys - p_keys).empty? || (e_keys.map(&:to_sym) - p_keys).empty?
              nargs = arguments.pop
            end
          end
          self.new(list: arguments, named: nargs)
        end

        # Validate defined arguments can be properly applied
        # to the given callable
        #
        # @param callable [Proc, Object] Instance that responds to #call or Proc
        def validate!(callable)
          params = callable.is_a?(Proc) ? callable.parameters :
            callable.method(:call).parameters
          l = list.dup
          n = named.dup
          params.each do |param|
            type, name = param
            case type
            when :key
              n.delete(name)
            when :keyreq
              if !n.key?(name)
                raise Error::InvalidArgumentsError,
                  "Missing named argument `#{name}' for action"
              end
              n.delete(name)
            when :keyrest
              n.clear
            when :rest
              l.clear
            when :req
              if l.size < 1
                raise Error::InvalidArgumentsError,
                  "Missing required argument `#{name}' for action"
              end
              l.shift
            when :opt
              l.shift
            end
          end
          raise Error::InvalidArgumentsError,
            "Too many arguments provided to action" if !l.empty?
          if !n.empty?
            keys = n.keys.map { |k| "#{k}'"}.join(", `")
            raise Error::InvalidArgumentsError,
              "Unknown named arguments provided to action `#{keys}'"
          end
          nil
        end
      end

      # @return [Stack] parent stack
      attr_reader :stack
      # @return [Object] callable
      attr_reader :callable
      # @return [Array<Object>, Arguments] arguments for callable
      attr_reader :arguments

      # Create a new action
      #
      # @param stack [Stack] stack associated with this action
      # @param callable [Object] callable item
      # @return [Action]
      def initialize(stack:, callable: nil, &block)
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
        @stack = stack
        @callable = c
        @called = false
        @arguments = []
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
          if callable.is_a?(Class)
            @callable = callable.new
          end
          if !callable.respond_to?(:call)
            raise ArgumentError,
              "Given callable does not respond to `#call'"
          end
          m = callable.method(:call)
          @arguments = Arguments.load(callable: m, arguments: @arguments)
          if m.parameters.any?{ |p| [:key, :keyreq].include?(p.first) && p.last == :context }
            @arguments.named[:context] = stack.context if !@arguments.key?(:context)
          end
          @arguments.validate!(m)
          @callable.freeze
          @arguments.freeze
        end
        self
      end

      # @return [Boolean] action has been called
      def called?
        !!@called
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
          callable.call(*arguments.list, **arguments.named)
        end
        stack.call(context: context)
      end
    end

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

    # Push a new callable action onto the end of the stack
    #
    # @param callable [Class, Proc] object that responds to #call or
    #        class with #call instance method
    # @return [Action] generated Action instance
    def push(callable=nil, &block)
      synchronize do
        be_unprepared!
        act = Action.new(stack: self, callable: callable, &block)
        @actions = ([act]+ actions).freeze
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
        @actions = (actions + [act]).freeze
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
        entry = @actions.delete(idx)
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
        @actions = actions.dup
        action = actions.pop
        @actions.freeze
        action
      end
    end

    # Remove first action from the stack
    #
    # @return [Action, nil]
    def shift
      synchronize do
        be_unprepared!
        @actions = actions.dup
        action = actions.shift
        @actions.freeze
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

    # Prepare the stack to be called
    #
    # @return [self]
    def prepare
      synchronize do
        be_unprepared!
        @actions = hooks.apply!
        @actions.freeze
        actions.each(&:prepare)
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
        if context
          be_unstarted!
          @context = context.for(self)
        end
        if @parallel
          acts = @actions.dup
          @actions = []
          acts.each do |action|
            Thread.new { action.call(context: @context) }
          end
        else
          action = pop
          action.call(context: context) if action
        end
      end
    end

    protected

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
