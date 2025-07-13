module Bogo
  class Stepper
    class Error < StandardError
      class CallableExecutedError < Error; end
      class CallableCleanedError < Error; end
      class StepExecutedError < Error; end
      class StepperInprogressError < Error; end
      class StepperExecutedError < Error; end
      class MultipleStepsError < Error; end
      class StepNotFoundError < Error; end
    end
  end
end
