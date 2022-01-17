require_relative '../spec'

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
      _(result.join(' ')).must_equal "that's what we're going to call it: i got worms"
    end

    it 'should allow block based cost' do
      q.push('last'){ 20 }
      q.push('first', 1)
      _(q.pop).must_equal 'first'
      _(q.pop).must_equal 'last'
    end

    it 'should dynamically sort block costs' do
      val = 20
      q.push('block'){ val }
      q.push('param', 1)
      val = 0
      _(q.pop).must_equal 'block'
      _(q.pop).must_equal 'param'
    end

    it 'should provide accurate size' do
      q.push('a', 1)
      q.push('b', 2)
      _(q.size).must_equal 2
    end

    it 'should determine if empty' do
      q.push('a', 1)
      _(q.empty?).must_equal false
      q.pop
      _(q.empty?).must_equal true
    end

    it 'should allow pushing muliple items at once' do
      q.multi_push([
          ['a', 1],
          ['b', 2],
          ['d', 4],
          ['c', 3],
          ['e', 5]
        ])
      %w(a b c d e).each do |chr|
        _(q.pop).must_equal chr
      end
    end

    it 'should allow pushing multiple items with block scores' do
      q.multi_push([
          ['a', 1],
          ['b', lambda{2}],
          ['d', 4],
          ['c', lambda{3}],
          ['e', 5]
        ])
      %w(a b c d e).each do |chr|
        _(q.pop).must_equal chr
      end
    end

    it 'should error when pushing multiple items with no score' do
      _(->{
          q.multi_push([
            ['a', 1],
            ['b'],
            ['d', 4],
            ['c', lambda{3}],
            ['e', 5]
          ])
        }
       ).must_raise ArgumentError
    end

    it 'should error when pushing non numeric/proc as score' do
      _(->{
          q.multi_push([
            ['a', 1],
            ['b', 'x'],
            ['d', 4],
            ['c', lambda{3}],
            ['e', 5]
          ])
        }
       ).must_raise ArgumentError
    end

    it 'should allow checking if item is already pushed' do
      q.push(1, 1)
      _(q.include?(1)).must_equal true
      _(q.include?(2)).must_equal false
    end

    it 'should order queue by high score if provided :highscore on init' do
      high_q = Bogo::PriorityQueue.new(:highscore)
      high_q.push('a', 1)
      high_q.push('b', 5)
      high_q.push('c', 2)
      _(high_q.pop).must_equal 'b'
      _(high_q.pop).must_equal 'c'
      _(high_q.pop).must_equal 'a'
    end
  end
end
