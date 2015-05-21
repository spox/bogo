require 'minitest/autorun'

describe Bogo::Lazy do

  before do
    @klass = Class.new
    @klass.instance_eval do
      include Bogo::Lazy

      attribute :stringer, String
      attribute :multi_type, [String, Integer]
      attribute :stringer_default, String, :default => 'ohai'
      attribute :integer_coerced, Integer, :coerce => lambda{|v| v.to_i}
      attribute :dependent_value, String, :depends => :value_loader
      attribute :missing_value, String
      attribute :stringer_multiple, String, :multiple => true
      attribute :stringer_multiple_coerce, String, :multiple => true, :coerce => lambda{|x| x.to_s}
      attribute :stringer_multiple_coerce_multiple, Integer, :multiple => true, :coerce => lambda{|x| {:bogo_multiple => x.split(',').map(&:to_i)} }

      on_missing :missing_loader
    end
    @klass.class_eval do
      def missing_loader
        data[:missing_value] = 'fubar'
      end

      def value_loader
        data[:dependent_value] = 'obai'
      end
    end
    @instance = @klass.new
  end

  let(:instance){ @instance }

  it 'should provide accessor and setter methods' do
    %w(stringer multi_type stringer_default integer_coerced).each do |name|
      instance.respond_to?(name).must_equal true
      instance.respond_to?("#{name}=").must_equal true
    end
  end

  it 'should only allow string value to be set' do
    instance.stringer = 'a string'
    instance.stringer.must_equal 'a string'
    ->{ instance.stringer = 1 }.must_raise(TypeError)
  end

  it 'should allow string or integer to be set' do
    instance.multi_type = 'a string'
    instance.multi_type.must_equal 'a string'
    instance.multi_type = 1
    instance.multi_type.must_equal 1
    ->{ instance.multi_type = :symbol }.must_raise(TypeError)
  end

  it 'should provide default value' do
    instance.stringer_default.must_equal 'ohai'
  end

  it 'should coerce value to expected type' do
    instance.integer_coerced = '100'
    instance.integer_coerced.must_equal 100
  end

  it 'should mark set values as dirty' do
    instance.stringer = 'a string'
    instance.dirty?(:stringer).must_equal true
    instance.dirty[:stringer].must_equal 'a string'
    instance.data[:string].wont_equal 'a string'
  end

  it 'should set defaults as non-dirty' do
    instance.dirty?(:stringer_default).must_equal false
    instance.data[:stringer_default].must_equal 'ohai'
  end

  it 'should merge #data and #dirty to provide #attributes' do
    instance.stringer = 'obai'
    instance.attributes[:stringer].must_equal 'obai'
    instance.attributes[:stringer_default].must_equal 'ohai'
  end

  it 'should return dirty values when set' do
    instance.stringer_default = 'obai'
    instance.stringer_default.must_equal 'obai'
    instance.dirty[:stringer_default].must_equal 'obai'
    instance.data[:stringer_default].must_equal 'ohai'
    instance.attributes[:stringer_default].must_equal 'obai'
  end

  it 'should call dependent method prior to value return' do
    instance.dependent_value.must_equal 'obai'
  end

  it 'should call missing method prior to value return' do
    instance.missing_value.must_equal 'fubar'
  end

  it 'should return if value is set' do
    instance.stringer_default?.must_equal true
    instance.stringer?.must_equal false
    instance.dependent_value?.must_equal true
  end

  it 'should merge #dirty into #data on #valid_state' do
    instance.stringer = 'a string'
    instance.dirty?(:stringer).must_equal true
    instance.dirty[:stringer].must_equal 'a string'
    instance.data[:stringer].wont_equal 'a string'
    instance.valid_state
    instance.dirty?(:stringer).must_equal false
    instance.dirty[:stringer].wont_equal 'a string'
    instance.data[:stringer].must_equal 'a string'
  end

  it 'should allow single values being set into multiple' do
    instance.stringer_multiple = 'a string'
    instance.stringer_multiple.must_equal ['a string']
  end

  it 'should allow multiple values being set into multiple' do
    instance.stringer_multiple = ['a string', 'an string']
    instance.stringer_multiple.must_equal ['a string', 'an string']
  end

  it 'should error when single value set into multple is incorrect type' do
    ->{ instance.stringer_multiple = 2 }.must_raise TypeError
  end

  it 'should coerce multiple values to correct types' do
    instance.stringer_multiple_coerce = [1, 2, '3']
    instance.stringer_multiple_coerce.must_equal ['1', '2', '3']
  end

  it 'should coerce multiple values to correct types and allow coerce block to return multiples' do
    instance.stringer_multiple_coerce_multiple = [1, 2, '3', '4,5,6']
    instance.stringer_multiple_coerce_multiple.must_equal [1, 2, 3, 4, 5, 6]
  end

end
