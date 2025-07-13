require_relative '../spec'

class BogoConstTop
  include Bogo::Constants
  FUBAR = 'ohai'

  def direct_const
    FUBAR
  end
end

class BogoConstSub < BogoConstTop
  FUBAR = 'bai'
end

module BogoNamespace
  module Fubar
    class Foobar
    end
  end
end

describe Bogo::Constants do
  describe 'Fetching constant value' do
    it 'should provide top level constant from top level object' do
      instance = BogoConstTop.new
      expect(instance.direct_const).to eq('ohai')
      expect(instance.const_val(:FUBAR)).to eq('ohai')
    end

    it 'should provide top level constant from sub object when direct' do
      instance = BogoConstSub.new
      expect(instance.direct_const).to eq('ohai')
    end

    it 'should provide local constant from sub object when using #const_val' do
      instance = BogoConstSub.new
      expect(instance.const_val(:FUBAR)).to eq('bai')
    end
  end

  describe 'Extracting constant from string' do
    before do
      @const = Object.new
      @const.extend Bogo::Constants
    end

    it 'should return expected class' do
      expect(@const.constantize('Bogo::AnimalStrings')).to eq(Bogo::AnimalStrings)
    end

    it 'should return expected value' do
      expect(@const.constantize('BogoConstTop::FUBAR')).to eq('ohai')
    end

    it 'should return nil when constant not found' do
      expect(@const.constantize('Bogo::Fubar')).to be_nil
    end
  end

  describe 'Providing namespace for class' do
    before do
      @const = Object.new
      @const.extend Bogo::Constants
    end

    it 'should return ObjectSpace when class is top level' do
      expect(@const.namespace(String)).to eq(ObjectSpace)
    end

    it 'should return parent namespace' do
      expect(@const.namespace(BogoNamespace::Fubar::Foobar.new)).to eq(BogoNamespace::Fubar)
    end
  end
end
