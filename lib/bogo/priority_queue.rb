require 'bogo'

module Bogo
  # Specialized priority based queue
  # @note does not allow duplicate objects to be queued
  class PriorityQueue

    # Create a new priority queue
    #
    # @return [self]
    def initialize(*args)
      @lock = Mutex.new
      @queue = Hash.new
      @block_costs = 0
      @reverse_sort = args.include?(:highscore)
    end

    # Push new item to the queue
    #
    # @param item [Object]
    # @param cost [Float]
    # @yield provide cost via proc
    # @return [self]
    def push(item, cost=nil, &block)
      lock.synchronize do
        if(queue[item])
          raise ArgumentError.new "Item already exists in queue. Items must be unique! (#{item})"
        end
        unless(cost || block_given?)
          raise ArgumentError.new 'Cost must be provided as parameter or block!'
        end
        @block_costs += 1 if cost.nil?
        queue[item] = cost || block
      end
      sort!
      self
    end

    # Push multiple items onto the queue at once
    #
    # @param items [Array<Array<item, cost>>]
    # @return [self]
    def multi_push(items)
      lock.synchronize do
        items.each do |item_pair|
          item, cost = item_pair
          if(queue[item])
            raise ArgumentError.new "Item already exists in queue. Items must be unique! (#{item})"
          end
          unless(cost.is_a?(Numeric) || cost.is_a?(Proc))
            raise ArgumentError.new "Cost must be provided as parameter or proc! (item: #{item})"
          end
          @block_costs += 1 if cost.is_a?(Proc)
          queue[item] = cost
        end
      end
      sort!
      self
    end

    # @return [Object, NilClass] item or nil if empty
    def pop
      sort! if @block_costs > 0
      lock.synchronize do
        item, score = queue.first
        @block_costs -= 1 if score.respond_to?(:call)
        queue.delete(item)
        item
      end
    end

    # @return [Integer] current size of queue
    def size
      lock.synchronize do
        queue.size
      end
    end

    # @return [TrueClass, FalseClass]
    def empty?
      size == 0
    end

    # @return [TrueClass, FalseClass]
    def include?(object)
      lock.synchronize do
        queue.keys.include?(object)
      end
    end

    # Sort the queue based on cost
    def sort!
      lock.synchronize do
        queue.replace(
          Hash[
            queue.sort do |x,y|
              x,y = y,x if @reverse_sort
              (x.last.respond_to?(:call) ? x.last.call : x.last).to_f <=>
                (y.last.respond_to?(:call) ? y.last.call : y.last).to_f
            end
          ]
        )
      end
    end

    protected

    attr_reader :queue, :lock

  end

end
