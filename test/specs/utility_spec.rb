require 'minitest/autorun'

describe Bogo::Utility do

  it 'should provide access to AnimalStrings helpers' do
    Bogo::Utility.must_respond_to :snake
    Bogo::Utility.must_respond_to :camel
  end

  it 'should provide access to Constants helpers' do
    Bogo::Utility.must_respond_to :constantize
    Bogo::Utility.must_respond_to :const_val
    Bogo::Utility.must_respond_to :namespace
  end

end
