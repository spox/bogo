require 'multi_json'
require 'monitor'
require 'digest/sha2'

module Bogo
  # Adds functionality to facilitate laziness
  module Lazy
    # Instance methods for laziness
    module InstanceMethods

      def self.included(klass)
        klass.include(MonitorMixin)
        klass.instance_variable_set(:@calling_on_missing, false)
      end

      # @return [Monitor] Monitor instance for synchronization
      def _mon
        @mon ||= Monitor.new
      end

      # @return [Smash] argument hash
      def data
        _mon.synchronize do
          unless(@data)
            @data = Smash.new
            self.class.attributes.each do |key, value|
              if(value.has_key?('default'))
                @data[key] = value['default']
              end
            end
          end
        end
        @data
      end

      # @return [Smash] updated data
      def dirty
        _mon.synchronize do
          unless(@dirty)
            @dirty = Smash.new
          end
        end
        @dirty
      end

      # @return [Smash] current data state
      def attributes
        _mon.synchronize { data.merge(dirty) }
      end

      # Create new instance
      #
      # @param args [Hash]
      # @return [self]
      def load_data(args={})
        _mon.synchronize do
          args = args.to_smash
          @data = Smash.new
          self.class.attributes.each do |name, options|
            val = args[name]
            if(options[:required] && !args.has_key?(name) && !options.has_key?(:default))
              raise ArgumentError.new("Missing required option: `#{name}`")
            end
            if(val.nil? && !args.has_key?(name) && options[:default])
              if(options[:default])
                val = options[:default].respond_to?(:call) ? options[:default].call : options[:default]
              end
            end
            if(args.has_key?(name) || val)
              self.send("#{name}=", val)
            end
          end
        end
        self
      end

      # Identifies valid state and automatically
      # merges dirty attributes into data, clears
      # dirty attributes
      #
      # @return [self]
      def valid_state
        _mon.synchronize do
          data.merge!(dirty)
          dirty.clear
          @_checksum = Digest::SHA256.hexdigest(MultiJson.dump(data.inspect).to_s)
        end
        self
      end

      # Model is dirty or specific attribute is dirty
      #
      # @param attr [String, Symbol] name of attribute
      # @return [TrueClass, FalseClass] model or attribute is dirty
      def dirty?(attr=nil)
        _mon.synchronize do
          if(attr)
            dirty.has_key?(attr)
          else
            if(@_checksum)
              !dirty.empty? ||
                @_checksum != Digest::SHA256.hexdigest(MultiJson.dump(data.inspect).to_s)
            else
              true
            end
          end
        end
      end

      # @return [String]
      def to_s
        "<#{self.class.name}:#{object_id}>"
      end

      # @return [String]
      def inspect
        "<#{self.class.name}:#{object_id} [#{data.inspect}]>"
      end

      # @return [Hash]
      def to_h
        _mon.synchronize do
          Hash[
            attributes.map{|k,v|
              [k, v.is_a?(Array) ?
                v.map{|x| x.respond_to?(:to_h) ? x.to_h : x} :
                v.respond_to?(:to_h) ? v.to_h : v]
            }
          ]
        end
      end
    end

    # Class methods for laziness
    module ClassMethods
      # Disable dirty state
      def always_clean!
        self.class_eval do
          def dirty?(*args); false; end
          def valid_state; self; end
          alias_method :dirty, :data
          alias_method :attributes, :data
        end
      end

      # Add new attributes to class
      #
      # @param name [String]
      # @param type [Class, Array<Class>]
      # @param options [Hash]
      # @option options [TrueClass, FalseClass] :required must be provided on initialization
      # @option options [Object, Proc] :default default value
      # @option options [Proc] :coerce
      # @return [nil]
      def attribute(name, type, options={})
        name = name.to_sym
        options = options.to_smash
        attributes[name] = Smash.new(:type => type).merge(options)
        coerce = attributes[name][:coerce]
        valid_types = [attributes[name][:type], NilClass].flatten.compact
        allowed_values = attributes[name][:allowed]
        multiple_values = attributes[name][:multiple]
        depends_on = attributes[name][:depends]
        define_method(name) do
          send(depends_on) if depends_on
          self.class.on_missing(self) unless data.has_key?(name) || dirty.has_key?(name)
          if(dirty.has_key?(name))
            dirty[name]
          else
            if(data.has_key?(name))
              val = data[name]
            else
              val = self.class.attributes[name][:default]
            end
            if(val.respond_to?(:dup))
              begin
                val = val.dup
              rescue
                val
              end
            end
            if(val.respond_to?(:freeze))
              val.freeze
            else
              val
            end
          end
        end
        define_method("#{name}=") do |val|
          values = multiple_values && val.is_a?(Array) ? val : [val]
          values.map! do |item|
            valid_type = valid_types.detect do |klass|
              item.is_a?(klass)
            end
            if(coerce && !valid_type)
              item = coerce.arity == 2 ? coerce.call(item, self) : coerce.call(item)
              if(item.is_a?(Hash) && item[:bogo_multiple])
                item = item[:bogo_multiple]
              else
                item = [item]
              end
            else
              item = [item]
            end
            invalid_type = item.detect do |_item|
              valid_types.none? do |klass|
                _item.is_a?(klass)
              end
            end
            if(invalid_type)
              raise TypeError.new("Invalid type for `#{name}` (#{invalid_type} <#{invalid_type.class}>). Valid - #{valid_types.map(&:to_s).join(',')}")
            end
            if(allowed_values)
              unallowed = item.detect do |_item|
                !allowed_values.include?(_item)
              end
              if(unallowed)
                raise ArgumentError.new("Invalid value provided for `#{name}` (#{unallowed.inspect}). Allowed - #{allowed_values.map(&:inspect).join(', ')}")
              end
            end
            item
          end
          values.flatten!(1)
          if(!multiple_values && !val.is_a?(Array))
            dirty[name] = values.first
          else
            dirty[name] = values
          end
        end
        define_method("#{name}?") do
          send(depends_on) if depends_on
          self.class.on_missing(self) unless data.has_key?(name)
          !!data[name]
        end
        nil
      end

      # Return attributes
      #
      # @param args [Symbol] :required or :optional
      # @return [Array<Hash>]
      def attributes(*args)
        @attributes ||= Smash.new
        if(args.include?(:required))
          Smash[@attributes.find_all{|k,v| v[:required]}]
        elsif(args.include?(:optional))
          Smash[@attributes.find_all{|k,v| !v[:required]}]
        else
          @attributes
        end
      end

      # Instance method to call on missing attribute or
      # object to call method on if set
      #
      # @param param [Symbol, Object]
      # @return [Symbol]
      def on_missing(param=nil)
        if(param)
          if(param.is_a?(Symbol))
            @missing_method = param
          else
            if(@missing_method && !@calling_on_missing)
              @calling_on_missing = true
              begin
                param.send(@missing_method)
              ensure
                @calling_on_missing = false
              end
            end
            @missing_method
          end
        else
          @missing_method
        end
      end

      # Directly set attribute hash
      #
      # @param attrs [Hash]
      # @return [TrueClass]
      # @todo need deep dup here
      def set_attributes(attrs)
        @attributes = attrs.to_smash
        true
      end
    end

    class << self
      # Injects laziness into class
      #
      # @param klass [Class]
      def included(klass)
        klass.class_eval do
          include InstanceMethods
          extend ClassMethods

          class << self
            def inherited(klass)
              klass.set_attributes(self.attributes.to_smash)
            end
          end
        end
      end
    end
  end
end
