require 'minitest/autorun'

describe Bogo::EphemeralFile do

  it 'should not exist after closing' do
    file = Bogo::EphemeralFile.new('bogo')
    path = file.path
    File.exists?(path).must_equal true
    file.close
    File.exists?(path).must_equal false
  end

end
