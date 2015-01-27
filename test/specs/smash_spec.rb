require 'minitest/autorun'

describe Bogo::Smash do

  it 'should provide top level constant' do
    Smash.must_equal Bogo::Smash
  end

  it 'should provide Hash to Smash conversion' do
    {:a => 1, :b => 2}.to_smash.class.must_equal Smash
  end

  it 'should provide Smash to Hash conversion' do
    Smash.new(:a => 1).to_hash.class.must_equal Hash
  end

  it 'should provide indifferent access' do
    instance = Smash.new(:a => 1)
    instance['a'].must_equal 1
    instance[:a].must_equal 1
  end

  it 'should convert nested Hash to Smash' do
    instance = Smash.new(
      :a => {
        :b => 1
      }
    )
    instance[:a].class.must_equal Smash
  end

  it 'should convert nested Array Hash to Smash' do
    instance = Smash.new(
      :a => [
        {:b => 1},
        {:c => 2}
      ]
    )
    instance[:a].first.class.must_equal Smash
    instance[:a].last.class.must_equal Smash
  end

  it 'should allow walking to value' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    instance.get(:a, :b, :c).must_equal 1
  end

  it 'should return nil when path is not set' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    instance.get(:a, :b, :d).must_equal nil
  end

  it 'should allow fetching existing value with default failover' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    instance.fetch(:a, :b, :c, 2).must_equal 1
  end

  it 'should allow fetching missing value and returning default failover' do
    instance = Smash.new(:a => {:b => {:c => 1}})
    instance.fetch(:a, :b, :d, 2).must_equal 2
  end

  it 'should allow setting new value with given path' do
    instance = Smash.new
    instance.set(:a, :b, :c, :d, :e, 1)
    instance.get(:a, :b, :c, :d, :e).must_equal 1
  end

  it 'should allow sorting keys on conversion' do
    instance = {:z => 1, :x => 2, :a => 3, :w => 4}
    instance.keys.must_equal [:z, :x, :a, :w]
    instance.to_smash(:sorted).keys.must_equal %w(a w x z)
  end

  it 'should provide consistent content checksums' do
    s1 = Smash.new(:a => 1, :z => 2, :d => 3, :b => {:w => 1, :a => 3})
    s2 = Smash.new(:b => {:a => 3, :w => 1}, :d => 3, :z => 2, :a => 1)
    s1.checksum.must_equal s2.checksum
  end

  it 'should convert Hashes in an Array to Smashes' do
    result = [
      {:a => true},
      [3, {:b => false}]
    ].to_smash
    result.first.must_be_kind_of Smash
    result.last.last.must_be_kind_of Smash
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
    result.must_be :frozen?
    result[:b][:c].must_be :frozen?
    result[:b][:c].first.must_be :frozen?
    result.get[:b][:c].last.must_be :frozen?
    result.get[:b][:c].first[:d].must_be :frozen?
  end

  it 'should camel case keys within Smash' do
    result = {
      :fubar => 1,
      :bing_bang => {
        :multi_word => 1
      }
    }.to_smash(:camel)
    result.keys.must_equal ['Fubar', 'BingBang']
    result['BingBang'].keys.must_equal ['MultiWord']
  end

  it 'should snake case keys within Smash' do
    result = {
      'Fubar' => 1,
      'BingBang' => {
        'MultiWord' => 1
      }
    }.to_smash(:snake)
    result.keys.must_equal ['fubar', 'bing_bang']
    result[:bing_bang].keys.must_equal ['multi_word']
  end

end
