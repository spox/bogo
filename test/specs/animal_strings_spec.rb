require 'minitest/autorun'

describe Bogo::AnimalStrings do

  before do
    @rawr = Object.new
    @rawr.extend Bogo::AnimalStrings
  end

  describe 'Snake casing' do

    it 'should snake camel cased string' do
      @rawr.snake('ThisIsCamelCased').must_equal 'this_is_camel_cased'
    end

    it 'should snake case weird camels' do
      @rawr.snake('thisIsCamelCaseD').must_equal 'this_is_camel_case_d'
      @rawr.snake('THISIsCamelCased').must_equal 'thisis_camel_cased'
    end

  end

  describe 'Camel Casing' do

    it 'should camel snake cased string' do
      @rawr.camel('this_is_camel_cased').must_equal 'ThisIsCamelCased'
    end

    it 'should camel case weird snakes' do
      @rawr.camel('_this_is_camel_cased').must_equal 'ThisIsCamelCased'
      @rawr.camel('_this_is_camel_cased_').must_equal 'ThisIsCamelCased'
      @rawr.camel('this__is_camel___cased').must_equal 'ThisIsCamelCased'
    end

  end

end
