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
      _(a.memoize(:x){ :fubar }).must_equal :fubar
      _(b.memoize(:x){ :feebar }).must_equal :feebar
      _(a.memoize(:x){ :foobar }).must_equal :fubar
      _(b.memoize(:x){ :foobar }).must_equal :feebar
    end

    it 'should unmemoize isolated to object' do
      a = @klass.new
      b = @klass.new
      _(a.memoize(:x){ :fubar }).must_equal :fubar
      _(b.memoize(:x){ :feebar }).must_equal :feebar
      a.unmemoize(:x)
      _(a.memoize(:x){ :foobar }).must_equal :foobar
      _(b.memoize(:x){ :foobar }).must_equal :feebar
    end

    it 'should memoize properly with multiple threads' do
      a = @klass.new
      b = @klass.new
      _(a.memoize(:x){ :fubar }).must_equal :fubar
      _(b.memoize(:x){ :feebar }).must_equal :feebar
      Thread.new do
        assert_equal :boom, a.memoize(:x){ :boom }
        assert_equal :blam, b.memoize(:x){ :blam }
        assert_equal :boom, a.memoize(:x){ :bang }
        assert_equal :blam, b.memoize(:x){ :bang }
      end.join
      _(a.memoize(:x){ :foobar }).must_equal :fubar
      _(b.memoize(:x){ :foobar }).must_equal :feebar
    end

    it 'should identify memoized value' do
      a = @klass.new
      a.memoize(:x){ :fubar }
      _(a.memoized?(:x)).must_equal true
      _(a.memoized?(:y)).must_equal false
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
      _(a.memoize(:x, true){ :fubar }).must_equal :fubar
      _(b.memoize(:x, true){ :feebar }).must_equal :fubar
      _(c.memoize(:x){ :feebar }).must_equal :feebar
      _(a.memoize(:x, true){ :foobar }).must_equal :fubar
      _(b.memoize(:x, true){ :foobar }).must_equal :fubar
      _(c.memoize(:x){ :foobar }).must_equal :feebar
      _(c.memoize(:x, true){ :foobar }).must_equal :fubar
    end

    it 'should unmemoize isolated to object' do
      a = @klass.new
      b = @klass.new
      _(a.memoize(:x, true){ :fubar }).must_equal :fubar
      _(b.memoize(:x, true){ :feebar }).must_equal :fubar
      a.unmemoize(:x, true)
      _(a.memoize(:x, true){ :foobar }).must_equal :foobar
      _(b.memoize(:x, true){ :fubar }).must_equal :foobar
    end

    it 'should memoize properly with multiple threads' do
      a = @klass.new
      b = @klass.new
      _(a.memoize(:x, true){ :fubar }).must_equal :fubar
      _(b.memoize(:x, true){ :feebar }).must_equal :fubar
      Thread.new do
        assert_equal :boom, a.memoize(:x, true){ :boom }
        assert_equal :boom, b.memoize(:x, true){ :blam }
        assert_equal :boom, a.memoize(:x, true){ :bang }
        assert_equal :boom, b.memoize(:x, true){ :bang }
      end.join
      _(a.memoize(:x, true){ :foobar }).must_equal :fubar
      _(b.memoize(:x, true){ :foobar }).must_equal :fubar
    end

    it 'should identify memoized value' do
      a = @klass.new
      a.memoize(:x, true){ :fubar }
      _(a.memoized?(:x, true)).must_equal true
      _(a.memoized?(:y, true)).must_equal false
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
      _(a.memoize(:x, :global){ :fubar }).must_equal :fubar
      _(b.memoize(:x, :global){ :feebar }).must_equal :fubar
      _(c.memoize(:x){ :feebar }).must_equal :feebar
      _(a.memoize(:x, :global){ :foobar }).must_equal :fubar
      _(b.memoize(:x, :global){ :foobar }).must_equal :fubar
      _(c.memoize(:x){ :foobar }).must_equal :feebar
      _(c.memoize(:x, :global){ :foobar }).must_equal :fubar
    end

    it 'should unmemoize isolated to object' do
      a = @klass.new
      b = @klass.new
      _(a.memoize(:x, :global){ :fubar }).must_equal :fubar
      _(b.memoize(:x, :global){ :feebar }).must_equal :fubar
      a.unmemoize(:x, :global)
      _(a.memoize(:x, :global){ :foobar }).must_equal :foobar
      _(b.memoize(:x, :global){ :fubar }).must_equal :foobar
    end

    it 'should memoize properly with multiple threads' do
      a = @klass.new
      b = @klass.new
      _(a.memoize(:x, :global){ :fubar }).must_equal :fubar
      _(b.memoize(:x, :global){ :feebar }).must_equal :fubar
      Thread.new do
        assert_equal :fubar, a.memoize(:x, :global){ :boom }
        assert_equal :fubar, b.memoize(:x, :global){ :blam }
        assert_equal :fubar, a.memoize(:x, :global){ :bang }
        assert_equal :fubar, b.memoize(:x, :global){ :bang }
      end.join
      _(a.memoize(:x, :global){ :foobar }).must_equal :fubar
      _(b.memoize(:x, :global){ :foobar }).must_equal :fubar
    end

    it 'should identify memoized value' do
      a = @klass.new
      a.memoize(:x, :global){ :fubar }
      _(a.memoized?(:x, :global)).must_equal true
      _(a.memoized?(:y, :global)).must_equal false
    end
  end
end
