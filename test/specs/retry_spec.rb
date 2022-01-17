require_relative '../spec'

describe Bogo::Retry do
  it 'should error on failure' do
    _(->{ Bogo::Retry.new{ raise 'error' } }).must_raise NotImplementedError
  end

  it 'should not error when auto run is disabled' do
    _(Bogo::Retry.new(:auto_run => false){ raise 'error' }).must_be_kind_of Bogo::Retry
  end

  it 'should error after maximum attempts' do
    _(->{ Bogo::Retry.new(:max_attempts => 1){ raise 'error' } }).must_raise RuntimeError
  end

  it 'should error if no block is provided' do
    _(->{ Bogo::Retry.new }).must_raise ArgumentError
  end

  it 'should build expected type of retry' do
    _(Bogo::Retry.build(:flat){true}).must_be_kind_of Bogo::Retry::Flat
  end

  describe Bogo::Retry::Flat do
    before do
      @retry = Bogo::Retry::Flat.new(
        :wait_interval => 3,
        :auto_run => false
      ){true}
    end

    it 'should always return the same wait interval' do
      _(@retry.send(:wait_on_failure, nil)).must_equal 3
      @retry.send(:log_attempt!)
      _(@retry.send(:wait_on_failure, nil)).must_equal 3
    end

  end

  describe Bogo::Retry::Linear do

    before do
      @retry = Bogo::Retry::Linear.new(
        :wait_interval => 3,
        :auto_run => false
      ){true}
    end

    it 'should return linear growth wait interval' do
      @retry.send(:log_attempt!)
      _(@retry.send(:wait_on_failure, nil)).must_equal 3
      @retry.send(:log_attempt!)
      _(@retry.send(:wait_on_failure, nil)).must_equal 6
      @retry.send(:log_attempt!)
      _(@retry.send(:wait_on_failure, nil)).must_equal 9
      @retry.send(:log_attempt!)
      _(@retry.send(:wait_on_failure, nil)).must_equal 12
      @retry.send(:log_attempt!)
      _(@retry.send(:wait_on_failure, nil)).must_equal 15
    end

  end

  describe Bogo::Retry::Exponential do

    before do
      @retry = Bogo::Retry::Exponential.new(
        :wait_interval => 3,
        :wait_exponent => 2,
        :auto_run => false
      ){true}
    end

    it 'should return linear growth wait interval' do
      @retry.send(:log_attempt!)
      _(@retry.send(:wait_on_failure, nil)).must_equal 3
      @retry.send(:log_attempt!)
      _(@retry.send(:wait_on_failure, nil)).must_equal 16
      @retry.send(:log_attempt!)
      _(@retry.send(:wait_on_failure, nil)).must_equal 25
      @retry.send(:log_attempt!)
      _(@retry.send(:wait_on_failure, nil)).must_equal 36
      @retry.send(:log_attempt!)
      _(@retry.send(:wait_on_failure, nil)).must_equal 49
    end
  end
end
