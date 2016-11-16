require 'hashie'
require 'digest/sha2'
require 'bogo'

module Bogo

  # Customized Hash
  class Smash < Hash

    class NoValue; end
    NO_VALUE = NoValue.new

    include Hashie::Extensions::IndifferentAccess
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::DeepMerge
    include Hashie::Extensions::Coercion

    coerce_value Hash, Smash

    # Create new instance
    #
    # @param args [Object] argument list
    def initialize(*args)
      base = nil
      if(args.first.is_a?(::Hash))
        base = args.shift
      end
      super *args
      if(base)
        self.replace(base.to_smash)
      end
    end

    def merge!(hash)
      hash = hash.to_smash
      super(hash)
    end

    def merge(hash)
      hash = hash.to_smash
      super(hash)
    end

    # Get value at given path
    #
    # @param args [String, Symbol] key path to walk
    # @return [Object, NoValue]
    # @note Ruby 2.3 introduced the Hash#dig method. Prefer
    #   it to injection method when available.
    if(superclass.instance_methods.include?(:dig))
      def retrieve(*args)
        prefix = args[0, args.size - 1]
        final = args.last
        result = prefix.empty? ? self : dig(*prefix)
        if(result.is_a?(Hash) && result.has_key?(final))
          result[final]
        else
          NO_VALUE
        end
      end
    else
      def retrieve(*args)
        args.inject(self) do |memo, key|
          if(memo.is_a?(Hash) && memo.has_key?(key))
            memo[key]
          else
            NO_VALUE
          end
        end
      end
    end

    # Get value at given path
    #
    # @param args [String, Symbol] key path to walk
    # @return [Object, NilClass]
    def get(*args)
      val = args.empty? ? self : retrieve(*args)
      val == NO_VALUE ? nil : val
    end

    # Fetch value at given path or return a default value
    #
    # @param args [String, Symbol, Object] key path to walk. last value default to return
    # @return [Object] value at key or default value
    def fetch(*args)
      default_value = args.pop
      val = retrieve(*args)
      val == NO_VALUE ? default_value : val
    end

    # Set value at given path
    #
    # @param args [String, Symbol, Object] key path to walk. set last value to given path
    # @return [Object] value set
    def set(*args)
      unless(args.size > 1)
        raise ArgumentError.new 'Set requires at least one key and a value'
      end
      value = args.pop
      set_key = args.pop
      leaf = args.inject(self) do |memo, key|
        unless(memo[key].is_a?(Hash))
          memo[key] = Smash.new
        end
        memo[key]
      end
      leaf[set_key] = value
      value
    end

    # Convert to Hash
    #
    # @return [Hash]
    def to_hash(*args)
      self.to_type_converter(::Hash, :to_hash, *args)
    end

    # Calculate checksum of hash (sha256)
    #
    # @return [String] checksum
    def checksum
      Digest::SHA256.hexdigest(self.to_smash(:sorted).to_s)
    end

  end
end

# Hook helper into toplevel `Hash`
class Hash

  # Convert to Smash
  #
  # @return [Smash]
  def to_smash(*args)
    self.to_type_converter(::Smash, :to_smash, *args)
  end
  alias_method :hulk_smash, :to_smash

  protected

  # Convert to type
  #
  # @param type [Class] hash type
  # @param convert_call [Symbol] builtin hash convert
  # @return [Smash]
  def to_type_converter(type, convert_call, *args)
    result = type.new.tap do |smash|
      if(args.include?(:sorted))
        process = self.sort_by do |entry|
          entry.first.to_s
        end
      else
        process = self
      end
      process.each do |k,v|
        if(args.include?(:snake))
          k = Bogo::Utility.snake(k.to_s)
        elsif(args.include?(:camel))
          k = Bogo::Utility.camel(k.to_s)
        end
        smash[k.is_a?(Symbol) ? k.to_s : k] = smash_conversion(v, convert_call, *args)
      end
    end
    if(args.include?(:freeze))
      result.values.map(&:freeze)
      result.freeze
    else
      result
    end
  end

  # Convert object to smash if applicable
  #
  # @param obj [Object]
  # @param convert_call [Symbol] builtin hash convert
  # @return [Smash, Object]
  def smash_conversion(obj, convert_call, *args)
    case obj
    when Hash
      obj.send(convert_call, *args)
    when Array
      obj.map do |i|
        result = smash_conversion(i, convert_call, *args)
        args.include?(:freeze) ? result.freeze : result
      end
    else
      args.include?(:freeze) ? obj.freeze : obj
    end
  end

end

class Array

  # Iterates searching for Hash types to auto convert
  #
  # @return [Array]
  def to_smash(*args)
    self.map do |item|
      if(item.respond_to?(:to_smash))
        item.to_smash(*args)
      else
        args.include?(:freeze) ? item.freeze : item
      end
    end
  end

end

unless(defined?(Smash))
  Smash = Bogo::Smash
end
