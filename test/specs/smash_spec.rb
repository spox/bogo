require_relative '../spec'

describe Bogo::Smash do
  it 'should provide top level constant' do
    _(Smash).must_equal Bogo::Smash
  end

  it 'should provide Hash to Smash conversion' do
    _({:a => 1, :b => 2}.to_smash.class).must_equal Smash
  end

  it 'should provide Smash to Hash conversion' do
    _(Smash.new(:a => 1).to_hash.class).must_equal Hash
  end

  it 'should provide indifferent access' do
    instance = Smash.new(:a => 1)
    _(instance['a']).must_equal 1
    _(instance[:a]).must_equal 1
  end

  it 'should convert nested Hash to Smash' do
    instance = Smash.new(
      :a => {
        :b => 1
      }
    )
    _(instance[:a].class).must_equal Smash
  end

  it 'should convert nested Array Hash to Smash' do
    instance = Smash.new(
      :a => [
        {:b => 1},
        {:c => 2}
      ]
    )
    _(instance[:a].first.class).must_equal Smash
    _(instance[:a].last.class).must_equal Smash
  end

  it 'should allow walking to value' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    _(instance.get(:a, :b, :c)).must_equal 1
  end

  it 'should return nil when path is not set' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    _(instance.get(:a, :b, :d)).must_be_nil
  end

  it 'should allow fetching existing value with default failover' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    _(instance.fetch(:a, :b, :c, 2)).must_equal 1
  end

  it 'should fetch false value' do
    instance = Smash.new(:a => {:b => {:c => false}})
    _(instance.fetch(:a, :b, :c, 2)).must_equal false
  end

  it 'should fetch nil value' do
    instance = Smash.new(:a => {:b => {:c => nil}})
    _(instance.fetch(:a, :b, :c, 2)).must_be_nil
  end

  it 'should raise error when not enough args provided to fetch' do
    instance = Smash.new(:a => {:b => {:c => nil}})
    _(->{ instance.fetch }).must_raise ArgumentError
  end

  it 'should return nil when default value not provided and value not found' do
    instance = Smash.new(:a => {:b => {:c => nil}})
    _(instance.fetch(:b)).must_be_nil
  end

  it 'should support a block defined default value' do
    instance = Smash.new(:a => {:b => {:c => nil}})
    _(instance.fetch(:z){ 'default_value' }).must_equal 'default_value'
  end

  it 'should receive smash instance when evaluating block default' do
    instance = Smash.new(:a => {:b => {:c => 'test_value'}})
    _(instance.fetch(:z){|i| i.get(:a, :b, :c)}).must_equal 'test_value'
  end

  it 'should allow fetching missing value and returning default failover' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    _(instance.fetch(:a, :b, :d, 2)).must_equal 2
  end

  it 'should allow setting new value with given path' do
    instance = Smash.new
    instance.set(:a, :b, :c, :d, :e, 1)
    _(instance.get(:a, :b, :c, :d, :e)).must_equal 1
  end

  it 'should allow sorting keys on conversion' do
    instance = {:z => 1, :x => 2, :a => 3, :w => 4}
    _(instance.keys).must_equal [:z, :x, :a, :w]
    _(instance.to_smash(:sorted).keys).must_equal %w(a w x z)
  end

  it 'should provide consistent content checksums' do
    s1 = Smash.new(:a => 1, :z => 2, :d => 3, :b => {:w => 1, :a => 3})
    s2 = Smash.new(:b => {:a => 3, :w => 1}, :d => 3, :z => 2, :a => 1)
    _(s1.checksum).must_equal s2.checksum
  end

  it 'should convert Hashes in an Array to Smashes' do
    result = [
      {:a => true},
      [3, {:b => false}]
    ].to_smash
    _(result.first).must_be_kind_of Smash
    _(result.last.last).must_be_kind_of Smash
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
    _(result).must_be :frozen?
    _(result[:b][:c]).must_be :frozen?
    _(result[:b][:c].first).must_be :frozen?
    _(result.get[:b][:c].last).must_be :frozen?
    _(result.get[:b][:c].first[:d]).must_be :frozen?
  end

  it 'should camel case keys within Smash' do
    result = {
      :fubar => 1,
      :bing_bang => {
        :multi_word => 1
      }
    }.to_smash(:camel)
    _(result.keys).must_equal ['Fubar', 'BingBang']
    _(result['BingBang'].keys).must_equal ['MultiWord']
  end

  it 'should snake case keys within Smash' do
    result = {
      'Fubar' => 1,
      'BingBang' => {
        'MultiWord' => 1
      }
    }.to_smash(:snake)
    _(result.keys).must_equal ['fubar', 'bing_bang']
    _(result[:bing_bang].keys).must_equal ['multi_word']
  end
end
