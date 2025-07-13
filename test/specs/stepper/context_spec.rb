require_relative "../../spec"

describe Bogo::Stepper::Context do
  describe "#initialize" do
    it "should not be halted" do
      expect(subject).not_to be_halted
    end

    it "should not be failed" do
      expect(subject).not_to be_failed
    end
  end
end
