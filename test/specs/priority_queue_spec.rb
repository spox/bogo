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
      expect(result.join(' ')).to eq("that's what we're going to call it: i got worms")
    end

    it 'should allow block based cost' do
      q.push('last'){ 20 }
      q.push('first', 1)
      expect(q.pop).to eq('first')
      expect(q.pop).to eq('last')
    end

    it 'should dynamically sort block costs' do
      val = 20
      q.push('block'){ val }
      q.push('param', 1)
      val = 0
      expect(q.pop).to eq('block')
      expect(q.pop).to eq('param')
    end

    it 'should provide accurate size' do
      q.push('a', 1)
      q.push('b', 2)
      expect(q.size).to eq(2)
    end

    it 'should determine if empty' do
      q.push('a', 1)
      expect(q.empty?).to eq(false)
      q.pop
      expect(q.empty?).to eq(true)
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
        expect(q.pop).to eq(chr)
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
        expect(q.pop).to eq(chr)
      end
    end

    it 'should error when pushing multiple items with no score' do
      expect {
        q.multi_push([
          ['a', 1],
          ['b'],
          ['d', 4],
          ['c', lambda{3}],
          ['e', 5]
                     ])
      }.to raise_error(ArgumentError)
    end

    it 'should error when pushing non numeric/proc as score' do
      expect {
        q.multi_push([
          ['a', 1],
          ['b', 'x'],
          ['d', 4],
          ['c', lambda{3}],
          ['e', 5]
                     ])
      }.to raise_error(ArgumentError)
    end

    it 'should allow checking if item is already pushed' do
      q.push(1, 1)
      expect(q.include?(1)).to eq(true)
      expect(q.include?(2)).to eq(false)
    end

    it 'should order queue by high score if provided :highscore on init' do
      high_q = Bogo::PriorityQueue.new(:highscore)
      high_q.push('a', 1)
      high_q.push('b', 5)
      high_q.push('c', 2)
      expect(high_q.pop).to eq('b')
      expect(high_q.pop).to eq('c')
      expect(high_q.pop).to eq('a')
    end
  end
end
