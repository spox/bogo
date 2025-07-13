require_relative '../spec'

describe Bogo::Lazy do

  describe 'Dirty behavior' do
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

    it 'should convert to a hash' do
      instance.stringer = 'a value'
      val = instance.to_h
      expect(val['stringer']).to eq('a value')
    end

    it 'should provide accessor and setter methods' do
      %w(stringer multi_type stringer_default integer_coerced).each do |name|
        expect(instance.respond_to?(name)).to eq(true)
        expect(instance.respond_to?("#{name}=")).to eq(true)
      end
    end

    it 'cannot not modify original value' do
      instance.stringer = 'a value'
      instance.valid_state
      expect(instance.stringer).to eq('a value')
      expect{ instance.stringer.replace('new value') }.to raise_error(FrozenError)
    end

    it 'can modify modified value' do
      instance.stringer = 'a value'
      instance.valid_state
      instance.stringer = 'new value'
      expect(instance.stringer.replace('replace value')).to eq('replace value')
    end

    it 'should only allow string value to be set' do
      instance.stringer = 'a string'
      expect(instance.stringer).to eq('a string')
      expect { instance.stringer = 1 }.to raise_error(TypeError)
    end

    it 'should allow string or integer to be set' do
      instance.multi_type = 'a string'
      expect(instance.multi_type).to eq('a string')
      instance.multi_type = 1
      expect(instance.multi_type).to eq(1)
      expect { instance.multi_type = :symbol }.to raise_error(TypeError)
    end

    it 'should provide default value' do
      expect(instance.stringer_default).to eq('ohai')
    end

    it 'should coerce value to expected type' do
      instance.integer_coerced = '100'
      expect(instance.integer_coerced).to eq(100)
    end

    it 'should mark set values as dirty' do
      instance.stringer = 'a string'
      expect(instance.dirty?(:stringer)).to eq(true)
      expect(instance.dirty[:stringer]).to eq('a string')
      expect(instance.data[:string]).not_to eq('a string')
    end

    it 'should set defaults as non-dirty' do
      expect(instance.dirty?(:stringer_default)).to eq(false)
      expect(instance.data[:stringer_default]).to eq('ohai')
    end

    it 'should merge #data and #dirty to provide #attributes' do
      instance.stringer = 'obai'
      expect(instance.attributes[:stringer]).to eq('obai')
      expect(instance.attributes[:stringer_default]).to eq('ohai')
    end

    it 'should return dirty values when set' do
      instance.stringer_default = 'obai'
      expect(instance.stringer_default).to eq('obai')
      expect(instance.dirty[:stringer_default]).to eq('obai')
      expect(instance.data[:stringer_default]).to eq('ohai')
      expect(instance.attributes[:stringer_default]).to eq('obai')
    end

    it 'should call dependent method prior to value return' do
      expect(instance.dependent_value).to eq('obai')
    end

    it 'should call missing method prior to value return' do
      expect(instance.missing_value).to eq('fubar')
    end

    it 'should return if value is set' do
      expect(instance.stringer_default?).to eq(true)
      expect(instance.stringer?).to eq(false)
      expect(instance.dependent_value?).to eq(true)
    end

    it 'should merge #dirty into #data on #valid_state' do
      instance.stringer = 'a string'
      expect(instance.dirty?(:stringer)).to eq(true)
      expect(instance.dirty[:stringer]).to eq('a string')
      expect(instance.data[:stringer]).not_to eq('a string')
      instance.valid_state
      expect(instance.dirty?(:stringer)).to eq(false)
      expect(instance.dirty[:stringer]).not_to eq('a string')
      expect(instance.data[:stringer]).to eq('a string')
    end

    it 'should allow single values being set into multiple' do
      instance.stringer_multiple = 'a string'
      expect(instance.stringer_multiple).to eq(['a string'])
    end

    it 'should allow multiple values being set into multiple' do
      instance.stringer_multiple = ['a string', 'an string']
      expect(instance.stringer_multiple).to eq(['a string', 'an string'])
    end

    it 'should error when single value set into multple is incorrect type' do
      expect { instance.stringer_multiple = 2 }.to raise_error(TypeError)
    end

    it 'should coerce multiple values to correct types' do
      instance.stringer_multiple_coerce = [1, 2, '3']
      expect(instance.stringer_multiple_coerce).to eq(['1', '2', '3'])
    end

    it 'should coerce multiple values to correct types and allow coerce block to return multiples' do
      instance.stringer_multiple_coerce_multiple = [1, 2, '3', '4,5,6']
      expect(instance.stringer_multiple_coerce_multiple).to eq([1, 2, 3, 4, 5, 6])
    end
  end

  describe 'Clean behavior' do

    before do
      @class = Class.new
      @class.instance_eval do
        include Bogo::Lazy
        attribute :stringer, String
        always_clean!
      end
      @instance = @class.new
    end

    let(:instance){ @instance }

    it 'should never be dirty' do
      instance.stringer = 'value'
      expect(instance.stringer).to eq('value')
      expect(instance.dirty[:stringer]).to eq('value')
      expect(instance.data[:stringer]).to eq('value')
      expect(instance.attributes[:stringer]).to eq('value')
      expect(instance.dirty?(:stringer)).to eq(false)
    end

    it 'should reference same data structures' do
      expect(instance.data).to eq(instance.dirty)
      expect(instance.dirty).to eq(instance.attributes)
      expect(
        [
          instance.data,
          instance.dirty,
          instance.attributes
        ].map(&:object_id).uniq
       ).to eq([instance.data.object_id])
    end
  end
end
