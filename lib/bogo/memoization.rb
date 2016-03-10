require 'bogo'

module Bogo
  # Memoization helpers
  module Memoization

    class << self

      # Clean up isolated memoizations
      #
      # @param object_id [Object]
      # @return [Proc]
      def cleanup(object_id)
        proc do
          Thread.current[:bogo_memoization].delete_if do |k,v|
            k.to_s.start_with?(object_id.to_s)
          end
        end
      end

      # Clear thread memoizations
      #
      # @return [nil]
      def clear_current!
        Thread.current[:bogo_memoization] = nil
      end

      # Clear global memoizations
      #
      # @return [nil]
      def clear_global!
        Thread.exclusive do
          $bogo_memoization = Smash.new
        end
      end

    end

    # Memoize data
    #
    # @param key [String, Symbol] identifier for data
    # @param direct [Truthy, Falsey] direct skips key prepend of object id
    # @yield block to create data
    # @yieldreturn data to memoize
    # @return [Object] data
    def memoize(key, direct=false)
      unless(direct)
        key = "#{self.object_id}_#{key}"
      end
      if(direct == :global)
        Thread.exclusive do
          $bogo_memoization ||= Smash.new
          unless($bogo_memoization.has_key?(key))
            $bogo_memoization[key] = yield
          end
          $bogo_memoization[key]
        end
      else
        unless(_memo.has_key?(key))
          _memo[key] = yield
        end
        _memo[key]
      end
    end

    # @return [Smash] memoization hash for current thread
    def _memo
      unless(Thread.current[:bogo_memoization])
        Thread.current[:bogo_memoization] = Smash.new
        ObjectSpace.define_finalizer(self, Bogo::Memoization.cleanup(self.object_id))
      end
      Thread.current[:bogo_memoization]
    end

    # Check if memoization entry for given key exists
    #
    # @param key [String, Symbol] identifier for data
    # @param direct [Truthy, Falsey] direct skips key prepend of object id
    # @return [TrueClass, FalseClass]
    def memoized?(key, direct=false)
      unless(direct)
        key = "#{self.object_id}_#{key}"
      end
      if(direct == :global)
        Thread.exclusive do
          $bogo_memoization ||= Smash.new
          $bogo_memoization.key?(key)
        end
      else
        _memo.key?(key)
      end
    end

    # Remove memoized value
    #
    # @param key [String, Symbol] identifier for data
    # @param direct [Truthy, Falsey] direct skips key prepend of object id
    # @return [Object] removed instance
    def unmemoize(key, direct=false)
      unless(direct)
        key = "#{self.object_id}_#{key}"
      end
      if(direct == :global)
        Thread.exclusive do
          $bogo_memoization ||= Smash.new
          $bogo_memoization.delete(key)
        end
      else
        _memo.delete(key)
      end
    end

    # Remove all memoized values
    #
    # @return [TrueClass]
    def clear_memoizations!
      _memo.keys.find_all do |key|
        key.to_s.start_with?("#{self.object_id}_")
      end.each do |key|
        _memo.delete(key)
      end
      true
    end

  end
end
