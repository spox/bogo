require "concurrent"
require "logger"

module Bogo
  class Logger
    module Helpers
      module InstanceMethods
        def logger
          self.class.logger
        end
      end

      module ClassMethods
        def logger_name(name)
          @_logger = logger.named(name.to_s)
        end

        def logger
          if !@_logger
            base = Utility.snake(self.name.
              split("::").first.downcase)
            @_logger = Bogo::Logger.logger.named(base)
          end
          @_logger
        end
      end

      def self.included(klass)
        klass.include(InstanceMethods)
        klass.extend(ClassMethods)
      end
    end

    # @return [Logger] default logger
    def self.logger
      if !@_logger
        @_logger = new
      end
      @_logger
    end

    # Create a new ::Logger instance wrapped
    # to allow threaded interactions
    def initialize(*logger_args)
      if logger_args.empty?
        logger_args = [$stderr]
      end
      @base_args = logger_args
      logger = ::Logger.new(*@base_args)
      logger.level = :fatal
      @wrapped_logger = Concurrent::MVar.new(logger)
    end

    # Create a new logger with the sub-name provided
    #
    # @param name [String] sub-name for logger
    # @return [Logger]
    def named(name)
      new_name = self.progname.to_s.dup
      new_name << "." unless new_name.empty?
      new_name << name
      new_logger = Logger.new(*@base_args)
      [:level, :formatter, :datetime_format].each do |m|
        new_logger.send("#{m}=", self.send(m))
      end
      new_logger.progname = new_name
      new_logger
    end

    ::Logger.instance_methods.each do |l_m|
      next if l_m.to_s.start_with?("_") || l_m.to_s == "object_id"
      class_eval <<-EOC
      def #{l_m}(*ma, &mb)
      wrapped_logger.borrow { |l| l.send(:#{l_m}, *ma, &mb) }
      end
      EOC
    end

    protected

    def wrapped_logger
      @wrapped_logger
    end
  end
end
