module Bogo
  class Stepper
    class Builder

      # @return [Stepper]
      attr_reader :stepper

      def initialize
        @stepper = Stepper.new
      end

      # Add a new step to the stepper
      #
      # @param [String] name name of step
      # @param [Callable, Class] callable callable class or instance
      def step(name, callable, **opts, &block)
        callable = callable.new if callable.is_a?(Class)

        raise TypeError,
          "Expecting Callable or block but received #{callable.class}" unless callable.is_a?(Callable)

        s = Step.new(name, callable)
        Array(opts[:depends_on]).each do |dep|
          if dep.is_a?(Symbol) || dep.is_a?(String)
            dep = stepper.find(dep)
            s.depends_on(dep)

            stepper.add(dep)
          end
        end

        stepper.add(s)

        return self if !block_given?

        builder = self.class.new
        builder.instance_eval(s, &block)
        stepper.add(Step.new("#{name}_nested", builder))

        self
      end
    end
  end
end
