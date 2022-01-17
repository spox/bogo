require_relative '../spec'

describe Bogo::EphemeralFile do
  it 'should not exist after closing' do
    file = Bogo::EphemeralFile.new('bogo')
    path = file.path
    _(File.exist?(path)).must_equal true
    file.close
    _(File.exist?(path)).must_equal false
  end
end
