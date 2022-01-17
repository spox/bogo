module Bogo
  # Perform action and retry until successful or abort
  class Retry
    # Create a type of retry
    #
    # @param type [String, Symbol] name of retry type
    # @param args [Object] instantiation arguments
    # @yield instantiation block
    # @return [Retry] specific subclass instance
    def self.build(type, *args, &block)
      klass = self.const_get(Bogo::Utility.camel(type))
      klass.new(*args, &block)
    end

    # @return [Proc] action to perform
    attr_reader :action
    # @return [Integer] number of attempts
    attr_reader :attempts
    # @return [TrueClass, FalseClass] retry is dead
    attr_reader :dead
    # @return [String] description of action
    attr_reader :description
    # @return [Integer] maximum number of attempts
    attr_reader :max_attempts
    # @return [Bogo::Ui] UI to direct warnings
    attr_reader :ui

    # Create a new retry instance
    #
    # @param args [Hash]
    # @option args [String] :description action description
    # @option args [Bogo::Ui] :ui output failure/retry notifications
    # @option args [Integer] :max_attempts maximum number of retries
    # @return [self]
    def initialize(args={}, &block)
      unless(block)
        raise ArgumentError,
          'Expecting block but no block was provided!'
      end
      args = args.to_smash
      @ui = args[:ui]
      @description = args.fetch(:description, 'Task')
      @max_attempts = args[:max_attempts]
      @action = block
      @attempts = 0
      @dead = false
      run! unless args[:auto_run] == false
    end

    # Run action until success
    #
    # @yield optional to allow custom exception check
    # @yieldparam [Exception] exception caught
    # @yieldreturn [TrueClass, FalseClass] if retry should be peformed
    # @return [Object] result of action
    def run!
      if(dead)
        raise RuntimeError,
          "Action has already reached maximum allowed attempts (#{max_attempts})!"
      else
        begin
          log_attempt!
          action.call
        rescue => e
          if(block_given?)
            raise unless yield(e)
          end
          if(max_attempts.nil? || attempts < max_attempts)
            interval = wait_on_failure(e)
            if(ui)
              if(max_attempts)
                attempt_info = "[Attempt #{attempts}/#{max_attempts}]"
              end
              ui.warn "#{description} failed (#{e.class}: #{e}) - Retry in #{interval.to_i} seconds #{attempt_info}"
            end
            sleep(interval)
            retry
          else
            if(ui && max_attempts.to_i > 0)
              ui.error "#{description} failed (#{e.class}: #{e}) - Maximum number of attempts reached!"
            end
            @dead = true
            raise e
          end
        end
      end
    end

    # @return [Integer]
    def retries
      attempts > 0 ? attempts - 1 : 0
    end

    protected

    # Amount of time to wait
    #
    # @param error [StandardError] failure exception
    # @return [Numeric] amount of wait time
    def wait_on_failure(error)
      raise NotImplementedError
    end

    # @return [Intenger]
    def log_attempt!
      @attempts = attempts.next
    end

    # Flat retry implementation
    class Flat < Retry
      # @return [Numeric]
      attr_reader :wait_interval

      # Create a new flat retry instance
      #
      # @param args [Hash]
      # @option args [Numeric] :wait_interval Defaults to 5 seconds
      # @return [self]
      def initialize(args={}, &block)
        @wait_interval = args[:wait_interval].to_f
        unless(@wait_interval > 0)
          @wait_interval = 5
        end
        super
      end

      protected

      # @return [Numeric] wait time
      def wait_on_failure(*_)
        wait_interval
      end
    end

    # Linear retry implementation
    class Linear < Retry
      # @return [Numeric]
      attr_reader :wait_interval

      # Create a new linear retry instance
      #
      # @param args [Hash]
      # @option args [Numeric] :wait_interval Defaults to 5 seconds
      # @return [self]
      def initialize(args={}, &block)
        @wait_interval = args[:wait_interval].to_f
        unless(@wait_interval > 0)
          @wait_interval = 5
        end
        super
      end

      protected

      # @return [Numeric] wait time
      def wait_on_failure(*_)
        wait_interval * attempts
      end
    end

    # Exponential retry implementation
    class Exponential < Retry
      # @return [Numeric]
      attr_reader :wait_interval
      # @return [Numeric]
      attr_reader :wait_exponent

      # Create a new linear retry instance
      #
      # @param args [Hash]
      # @option args [Numeric] :wait_interval Defaults to 5 seconds
      # @option args [Numeric] :wait_exponent Defaults to 2
      # @return [self]
      def initialize(args={}, &block)
        @wait_interval = args[:wait_interval].to_f
        @wait_exponent = args[:wait_exponent].to_f
        unless(@wait_interval > 0)
          @wait_interval = 5
        end
        unless(@wait_exponent > 0)
          @wait_exponent = 2
        end
        super
      end

      protected

      # @return [Numeric] wait time
      def wait_on_failure(*_)
        retries == 0 ? wait_interval : (wait_interval + retries) ** wait_exponent
      end
    end
  end
end
