require "monitor"

module Bogo
  class Stepper
    class Context
      include MonitorMixin

      def initialize
        @lock = Mutex.new
        @data = Hash.new
        @failed = false
        @interrupted = false
      end

      def set(key, value)
        @lock.synchronize do
          @data[key] = value
        end
      end

      def get(key)
        @lock.synchronize do
          @data[key]
        end
      end

      def synchronize
        @lock.synchronize do
          yield
        end
      end

      def halted?
        failed? || interrupted?
      end

      def failed?
        @lock.synchronize { @failed }
      end

      def interrupted?
        @lock.synchronize { @interrupted }
      end

      def failed=(val)
        @lock.synchronize { @failed = !!val }
      end

      def interrupted=(val)
        @lock.synchronize { @interrupted = !!val }
      end
    end
  end
end
