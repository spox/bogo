module Bogo
  class Stack
    # Stack related errors
    class Error < StandardError
      class PreparedError < Error; end
      class UnpreparedError < Error; end
      class ApplyError < Error; end
      class CalledError < Error; end
      class InvalidArgumentsError < Error; end
      class StackFailure < Error
        attr_reader :errors
        def initialize(errors)
          msg = []
          @errors = errors.map { |src, err|
            raise TypeError,
              "expected 'Exception' type but received '#{err.class}'" unless err.is_a?(Exception)
            msg << err.message
            err
          }.freeze

          super("* " + msg.join("\n* "))
        end
      end
    end
  end
end
