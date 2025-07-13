require_relative '../spec'

describe Bogo::Smash do
  it 'should provide top level constant' do
    expect(Smash).to eq(Bogo::Smash)
  end

  it 'should provide Hash to Smash conversion' do
    expect({:a => 1, :b => 2}.to_smash.class).to eq(Smash)
  end

  it 'should provide Smash to Hash conversion' do
    expect(Smash.new(:a => 1).to_hash.class).to eq(Hash)
  end

  it 'should provide indifferent access' do
    instance = Smash.new(:a => 1)
    expect(instance['a']).to eq(1)
    expect(instance[:a]).to eq(1)
  end

  it 'should convert nested Hash to Smash' do
    instance = Smash.new(
      :a => {
        :b => 1
      }
    )
    expect(instance[:a].class).to eq(Smash)
  end

  it 'should convert nested Array Hash to Smash' do
    instance = Smash.new(
      :a => [
        {:b => 1},
        {:c => 2}
      ]
    )
    expect(instance[:a].first.class).to eq(Smash)
    expect(instance[:a].last.class).to eq(Smash)
  end

  it 'should allow walking to value' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    expect(instance.get(:a, :b, :c)).to eq(1)
  end

  it 'should return nil when path is not set' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    expect(instance.get(:a, :b, :d)).to be_nil
  end

  it 'should allow fetching existing value with default failover' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    expect(instance.fetch(:a, :b, :c, 2)).to eq(1)
  end

  it 'should fetch false value' do
    instance = Smash.new(:a => {:b => {:c => false}})
    expect(instance.fetch(:a, :b, :c, 2)).to eq(false)
  end

  it 'should fetch nil value' do
    instance = Smash.new(:a => {:b => {:c => nil}})
    expect(instance.fetch(:a, :b, :c, 2)).to be_nil
  end

  it 'should raise error when not enough args provided to fetch' do
    instance = Smash.new(:a => {:b => {:c => nil}})
    expect { instance.fetch }.to raise_error(ArgumentError)
  end

  it 'should return nil when default value not provided and value not found' do
    instance = Smash.new(:a => {:b => {:c => nil}})
    expect(instance.fetch(:b)).to be_nil
  end

  it 'should support a block defined default value' do
    instance = Smash.new(:a => {:b => {:c => nil}})
    expect(instance.fetch(:z){ 'default_value' }).to eq('default_value')
  end

  it 'should receive smash instance when evaluating block default' do
    instance = Smash.new(:a => {:b => {:c => 'test_value'}})
    expect(instance.fetch(:z){|i| i.get(:a, :b, :c)}).to eq('test_value')
  end

  it 'should allow fetching missing value and returning default failover' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    expect(instance.fetch(:a, :b, :d, 2)).to eq(2)
  end

  it 'should allow setting new value with given path' do
    instance = Smash.new
    instance.set(:a, :b, :c, :d, :e, 1)
    expect(instance.get(:a, :b, :c, :d, :e)).to eq(1)
  end

  it 'should allow sorting keys on conversion' do
    instance = {:z => 1, :x => 2, :a => 3, :w => 4}
    expect(instance.keys).to eq([:z, :x, :a, :w])
    expect(instance.to_smash(:sorted).keys).to eq(%w(a w x z))
  end

  it 'should provide consistent content checksums' do
    s1 = Smash.new(:a => 1, :z => 2, :d => 3, :b => {:w => 1, :a => 3})
    s2 = Smash.new(:b => {:a => 3, :w => 1}, :d => 3, :z => 2, :a => 1)
    expect(s1.checksum).to eq(s2.checksum)
  end

  it 'should convert Hashes in an Array to Smashes' do
    result = [
      {:a => true},
      [3, {:b => false}]
    ].to_smash
    expect(result.first).to be_kind_of(Smash)
    expect(result.last.last).to be_kind_of(Smash)
  end

  it 'should freeze entire Smash' do
    result = {
      :a => 'fubar',
      :b => {
        :c => [
          {:d => 'hi'},
          'testing'
        ],
      }
    }.to_smash(:freeze)
    expect(result).to be_frozen
    expect(result[:b][:c]).to be_frozen
    expect(result[:b][:c].first).to be_frozen
    expect(result.get[:b][:c].last).to be_frozen
    expect(result.get[:b][:c].first[:d]).to be_frozen
  end

  it 'should camel case keys within Smash' do
    result = {
      :fubar => 1,
      :bing_bang => {
        :multi_word => 1
      }
    }.to_smash(:camel)
    expect(result.keys).to eq(['Fubar', 'BingBang'])
    expect(result['BingBang'].keys).to eq(['MultiWord'])
  end

  it 'should snake case keys within Smash' do
    result = {
      'Fubar' => 1,
      'BingBang' => {
        'MultiWord' => 1
      }
    }.to_smash(:snake)
    expect(result.keys).to eq(['fubar', 'bing_bang'])
    expect(result[:bing_bang].keys).to eq(['multi_word'])
  end
end
