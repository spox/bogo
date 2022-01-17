require_relative '../spec'

describe Bogo::Utility do
  it 'should provide access to AnimalStrings helpers' do
    _(Bogo::Utility).must_respond_to :snake
    _(Bogo::Utility).must_respond_to :camel
  end

  it 'should provide access to Constants helpers' do
    _(Bogo::Utility).must_respond_to :constantize
    _(Bogo::Utility).must_respond_to :const_val
    _(Bogo::Utility).must_respond_to :namespace
  end
end
