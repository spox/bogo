module Bogo
  class Stack
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
  end
end
