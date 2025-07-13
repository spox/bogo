module Bogo
  class Stack
    class Action
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
          @valid = Set.new
        end

        # Check if name is a valid named argument
        #
        # @param [String, Symbol] name argument name
        # @return [TrueClass, FalseClass]
        def named?(name)
          @valid.include?(name.to_sym)
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
            valid_keys = p_keys & e_keys
            nargs = arguments.pop.slice(*valid_keys)
          end
          self.new(list: arguments, named: nargs).tap { |args| args.validate!(callable) }
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
              n.delete(name.to_sym)
            when :keyreq
              if !n.key?(name.to_sym)
                raise Error::InvalidArgumentsError,
                  "Missing named argument `#{name}' for action"
              end
              n.delete(name.to_sym)
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
    end
  end
end
