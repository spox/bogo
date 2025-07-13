require_relative '../spec'

describe Bogo::Utility do
  it 'should provide access to AnimalStrings helpers' do
    expect(Bogo::Utility).to respond_to(:snake)
    expect(Bogo::Utility).to respond_to(:camel)
  end

  it 'should provide access to Constants helpers' do
    expect(Bogo::Utility).to respond_to(:constantize)
    expect(Bogo::Utility).to respond_to(:const_val)
    expect(Bogo::Utility).to respond_to(:namespace)
  end
end
