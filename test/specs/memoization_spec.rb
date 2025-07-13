require_relative '../spec'

describe Bogo::Memoization do
  before do
    @klass = Class.new
    @klass.include Bogo::Memoization
  end

  describe 'Isolated memoziation' do
    it 'should memoize isolated to object' do
      a = @klass.new
      b = @klass.new
      expect(a.memoize(:x){ :fubar }).to eq(:fubar)
      expect(b.memoize(:x){ :feebar }).to eq(:feebar)
      expect(a.memoize(:x){ :foobar }).to eq(:fubar)
      expect(b.memoize(:x){ :foobar }).to eq(:feebar)
    end

    it 'should unmemoize isolated to object' do
      a = @klass.new
      b = @klass.new
      expect(a.memoize(:x){ :fubar }).to eq(:fubar)
      expect(b.memoize(:x){ :feebar }).to eq(:feebar)
      a.unmemoize(:x)
      expect(a.memoize(:x){ :foobar }).to eq(:foobar)
      expect(b.memoize(:x){ :foobar }).to eq(:feebar)
    end

    it 'should memoize properly with multiple threads' do
      a = @klass.new
      b = @klass.new
      expect(a.memoize(:x){ :fubar }).to eq(:fubar)
      expect(b.memoize(:x){ :feebar }).to eq(:feebar)
      Thread.new do
        expect(a.memoize(:x){ :boom }).to eq(:boom)
        expect(b.memoize(:x){ :blam }).to eq(:blam)
        expect(a.memoize(:x){ :bang }).to eq(:boom)
        expect(b.memoize(:x){ :bang }).to eq(:blam)
      end.join
      expect(a.memoize(:x){ :foobar }).to eq(:fubar)
      expect(b.memoize(:x){ :foobar }).to eq(:feebar)
    end

    it 'should identify memoized value' do
      a = @klass.new
      a.memoize(:x){ :fubar }
      expect(a.memoized?(:x)).to eq(true)
      expect(a.memoized?(:y)).to eq(false)
    end
  end

  describe 'Non-isolated memoization' do
    before do
      Bogo::Memoization.clear_current!
    end

    it 'should memoize not isolated to object' do
      a = @klass.new
      b = @klass.new
      c = @klass.new
      expect(a.memoize(:x, true){ :fubar }).to eq(:fubar)
      expect(b.memoize(:x, true){ :feebar }).to eq(:fubar)
      expect(c.memoize(:x){ :feebar }).to eq(:feebar)
      expect(a.memoize(:x, true){ :foobar }).to eq(:fubar)
      expect(b.memoize(:x, true){ :foobar }).to eq(:fubar)
      expect(c.memoize(:x){ :foobar }).to eq(:feebar)
      expect(c.memoize(:x, true){ :foobar }).to eq(:fubar)
    end

    it 'should unmemoize isolated to object' do
      a = @klass.new
      b = @klass.new
      expect(a.memoize(:x, true){ :fubar }).to eq(:fubar)
      expect(b.memoize(:x, true){ :feebar }).to eq(:fubar)
      a.unmemoize(:x, true)
      expect(a.memoize(:x, true){ :foobar }).to eq(:foobar)
      expect(b.memoize(:x, true){ :fubar }).to eq(:foobar)
    end

    it 'should memoize properly with multiple threads' do
      a = @klass.new
      b = @klass.new
      expect(a.memoize(:x, true){ :fubar }).to eq(:fubar)
      expect(b.memoize(:x, true){ :feebar }).to eq(:fubar)
      Thread.new do
        expect(a.memoize(:x, true){ :boom }).to eq(:boom)
        expect(b.memoize(:x, true){ :blam }).to eq(:boom)
        expect(a.memoize(:x, true){ :bang }).to eq(:boom)
        expect(b.memoize(:x, true){ :bang }).to eq(:boom)
      end.join
      expect(a.memoize(:x, true){ :foobar }).to eq(:fubar)
      expect(b.memoize(:x, true){ :foobar }).to eq(:fubar)
    end

    it 'should identify memoized value' do
      a = @klass.new
      a.memoize(:x, true){ :fubar }
      expect(a.memoized?(:x, true)).to eq(true)
      expect(a.memoized?(:y, true)).to eq(false)
    end

  end

  describe 'Global memoization' do
    before do
      Bogo::Memoization.clear_global!
      Bogo::Memoization.clear_current!
    end

    it 'should memoize not isolated to object' do
      a = @klass.new
      b = @klass.new
      c = @klass.new
      expect(a.memoize(:x, :global){ :fubar }).to eq(:fubar)
      expect(b.memoize(:x, :global){ :feebar }).to eq(:fubar)
      expect(c.memoize(:x){ :feebar }).to eq(:feebar)
      expect(a.memoize(:x, :global){ :foobar }).to eq(:fubar)
      expect(b.memoize(:x, :global){ :foobar }).to eq(:fubar)
      expect(c.memoize(:x){ :foobar }).to eq(:feebar)
      expect(c.memoize(:x, :global){ :foobar }).to eq(:fubar)
    end

    it 'should unmemoize isolated to object' do
      a = @klass.new
      b = @klass.new
      expect(a.memoize(:x, :global){ :fubar }).to eq(:fubar)
      expect(b.memoize(:x, :global){ :feebar }).to eq(:fubar)
      a.unmemoize(:x, :global)
      expect(a.memoize(:x, :global){ :foobar }).to eq(:foobar)
      expect(b.memoize(:x, :global){ :fubar }).to eq(:foobar)
    end

    it 'should memoize properly with multiple threads' do
      a = @klass.new
      b = @klass.new
      expect(a.memoize(:x, :global){ :fubar }).to eq(:fubar)
      expect(b.memoize(:x, :global){ :feebar }).to eq(:fubar)
      Thread.new do
        expect(a.memoize(:x, :global){ :boom }).to eq(:fubar)
        expect(b.memoize(:x, :global){ :blam }).to eq(:fubar)
        expect(a.memoize(:x, :global){ :bang }).to eq(:fubar)
        expect(b.memoize(:x, :global){ :bang }).to eq(:fubar)
      end.join
      expect(a.memoize(:x, :global){ :foobar }).to eq(:fubar)
      expect(b.memoize(:x, :global){ :foobar }).to eq(:fubar)
    end

    it 'should identify memoized value' do
      a = @klass.new
      a.memoize(:x, :global){ :fubar }
      expect(a.memoized?(:x, :global)).to eq(true)
      expect(a.memoized?(:y, :global)).to eq(false)
    end
  end
end
