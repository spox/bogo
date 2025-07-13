require_relative '../spec'

describe Bogo::AnimalStrings do
  before do
    @rawr = Object.new
    @rawr.extend Bogo::AnimalStrings
  end

  describe 'Snake casing' do
    it 'should snake camel cased string' do
      expect(@rawr.snake('ThisIsCamelCased')).to eq('this_is_camel_cased')
    end

    it 'should snake case weird camels' do
      expect(@rawr.snake('thisIsCamelCaseD')).to eq('this_is_camel_case_d')
      expect(@rawr.snake('THISIsCamelCased')).to eq('thisis_camel_cased')
    end
  end

  describe 'Camel Casing' do
    it 'should camel snake cased string' do
      expect(@rawr.camel('this_is_camel_cased')).to eq('ThisIsCamelCased')
    end

    it 'should camel case weird snakes' do
      expect(@rawr.camel('_this_is_camel_cased')).to eq('ThisIsCamelCased')
      expect(@rawr.camel('_this_is_camel_cased_')).to eq('ThisIsCamelCased')
      expect(@rawr.camel('this__is_camel___cased')).to eq('ThisIsCamelCased')
    end

    it 'should support leading lower case camel' do
      expect(@rawr.camel('this_is_camel_cased', false)).to eq('thisIsCamelCased')
    end
  end
end
