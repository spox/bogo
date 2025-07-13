module Bogo
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
            item == :stub ? actions.shift : item
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
          prepend_entries + actions + append_entries
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
  end
end
