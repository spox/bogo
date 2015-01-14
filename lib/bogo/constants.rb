require 'bogo'

module Bogo

  # Constant helper
  module Constants

    # Convert string to constant
    #
    # @param string [String] full constant name
    # @return [Object]
    def constantize(string)
      string.split('::').inject(ObjectSpace) do |memo, key|
        break unless memo.const_defined?(key)
        memo.const_get(key)
      end
    end

    # Return constant value localized to calling instance class
    #
    # @param name [String, Symbol] constant name
    # @return [Object]
    def const_val(name)
      self.class.const_get(name)
    end

    # Provides namespace constant
    #
    # @param inst [Object]
    # @return [Class, Module]
    def namespace(inst = self)
      klass = inst.class.name.split('::')
      klass.pop
      if(klass.empty?)
        ObjectSpace
      else
        constantize(klass.join('::'))
      end
    end

  end

end
