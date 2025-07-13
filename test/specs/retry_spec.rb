require_relative '../spec'

describe Bogo::Retry do
  it 'should error on failure' do
    expect { Bogo::Retry.new{ raise 'error' } }.to raise_error(NotImplementedError)
  end

  it 'should not error when auto run is disabled' do
    expect(Bogo::Retry.new(:auto_run => false){ raise 'error' }).to be_kind_of(Bogo::Retry)
  end

  it 'should error after maximum attempts' do
    expect { Bogo::Retry.new(:max_attempts => 1){ raise 'error' } }.to raise_error(RuntimeError)
  end

  it 'should error if no block is provided' do
    expect { Bogo::Retry.new }.to raise_error(ArgumentError)
  end

  it 'should build expected type of retry' do
    expect(Bogo::Retry.build(:flat){true}).to be_kind_of(Bogo::Retry::Flat)
  end

  describe Bogo::Retry::Flat do
    before do
      @retry = Bogo::Retry::Flat.new(
        :wait_interval => 3,
        :auto_run => false
      ){true}
    end

    it 'should always return the same wait interval' do
      expect(@retry.send(:wait_on_failure, nil)).to eq(3)
      @retry.send(:log_attempt!)
      expect(@retry.send(:wait_on_failure, nil)).to eq(3)
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
      expect(@retry.send(:wait_on_failure, nil)).to eq(3)
      @retry.send(:log_attempt!)
      expect(@retry.send(:wait_on_failure, nil)).to eq(6)
      @retry.send(:log_attempt!)
      expect(@retry.send(:wait_on_failure, nil)).to eq(9)
      @retry.send(:log_attempt!)
      expect(@retry.send(:wait_on_failure, nil)).to eq(12)
      @retry.send(:log_attempt!)
      expect(@retry.send(:wait_on_failure, nil)).to eq(15)
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
      expect(@retry.send(:wait_on_failure, nil)).to eq(3)
      @retry.send(:log_attempt!)
      expect(@retry.send(:wait_on_failure, nil)).to eq(16)
      @retry.send(:log_attempt!)
      expect(@retry.send(:wait_on_failure, nil)).to eq(25)
      @retry.send(:log_attempt!)
      expect(@retry.send(:wait_on_failure, nil)).to eq(36)
      @retry.send(:log_attempt!)
      expect(@retry.send(:wait_on_failure, nil)).to eq(49)
    end
  end
end
