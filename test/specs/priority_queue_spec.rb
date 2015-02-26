require 'bogo'
require 'minitest/autorun'

describe Bogo::PriorityQueue do

  before do
    @q = Bogo::PriorityQueue.new
  end

  let(:q){ @q }

  describe 'Queue behavior' do

    it 'should return items based on cost' do
      q.push('worms', 10)
      q.push("that's", 1)
      q.push('what', 2)
      q.push('call', 6)
      q.push('it:', 7)
      q.push('to', 5)
      q.push('going', 4)
      q.push('got', 9)
      q.push('i', 8)
      q.push("we're", 3)
      result = []
      10.times{ result.push(q.pop) }
      result.join(' ').must_equal "that's what we're going to call it: i got worms"
    end

    it 'should allow block based cost' do
      q.push('last'){ 20 }
      q.push('first', 1)
      q.pop.must_equal 'first'
      q.pop.must_equal 'last'
    end

    it 'should dynamically sort block costs' do
      val = 20
      q.push('block'){ val }
      q.push('param', 1)
      val = 0
      q.pop.must_equal 'block'
      q.pop.must_equal 'param'
    end

    it 'should provide accurate size' do
      q.push('a', 1)
      q.push('b', 2)
      q.size.must_equal 2
    end

    it 'should determine if empty' do
      q.push('a', 1)
      q.empty?.must_equal false
      q.pop
      q.empty?.must_equal true
    end

  end
end
