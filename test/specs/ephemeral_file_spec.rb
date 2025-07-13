require_relative '../spec'

describe Bogo::EphemeralFile do
  it 'should not exist after closing' do
    file = Bogo::EphemeralFile.new('bogo')
    path = file.path
    expect(File.exist?(path)).to eq(true)
    file.close
    expect(File.exist?(path)).to eq(false)
  end
end
