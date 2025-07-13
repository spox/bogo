require_relative '../../spec'

describe Bogo::Stack::Context do
  let(:stack) { Bogo::Stack.new }
  subject { described_class.new(stack: stack) }

  describe "#stacks" do
    it "should have initial stack in list" do
      expect(subject.stacks).to include(stack)
    end

    it "should be frozen" do
      expect(subject.stacks).to be_frozen
    end

    it "should only include initial stack" do
      expect(subject.stacks).to eq([stack])
    end
  end

  describe "#for" do
    let(:stack2) { Bogo::Stack.new }

    it "should add new stack to the list" do
      subject.for(stack2)
      expect(subject.stacks).to include(stack)
      expect(subject.stacks).to include(stack2)
    end

    it "should freeze list after modifying" do
      subject.for(stack2)
      expect(subject.stacks).to be_frozen
    end

    it "should return self" do
      expect(subject.for(stack2)).to eq(subject)
    end
  end

  describe "#is_set?" do
    it "should return true if value has been set" do
      subject.set(:key, :path, "value")
      expect(subject.is_set?(:key, :path)).to eq(true)
    end

    it "should return false if value has not been set" do
      expect(subject.is_set?(:key, :path)).to eq(false)
    end
  end

  describe "#get" do
    it "should return value when set" do
      subject.set(:key, :path, "value")
      expect(subject.get(:key, :path)).to eq("value")
    end

    it "should wait for value when not set" do
      result = nil
      t_get = Thread.new { result = subject.get(:key, :path) }

      expect(subject.is_set?(:key, :path)).to eq(false)
      expect(result).to be_nil

      t_set = Thread.new { subject.set(:key, :path, "value") }
      t_set.join

      expect(subject.is_set?(:key, :path)).to eq(true)

      t_get.join

      expect(result).to eq("value")
    end
  end

  describe "#grab" do
    it "should return value when set" do
      subject.set(:key, :path, "value")
      expect(subject.grab(:key, :path)).to eq("value")
    end

    it "should return nil when value is unset" do
      expect(subject.grab(:key, :path)).to be_nil
    end
  end

  describe "#set" do
    it "should set value" do
      subject.set(:key, :path, "value")
      expect(subject.grab(:key, :path)).to eq("value")
    end

    it "should notify all waiters when setting value" do
      result = []
      t = []
      t << Thread.new { result << subject.get(:key, :path) }
      t << Thread.new { result << subject.get(:key, :path) }
      t << Thread.new { result << subject.get(:key, :path) }

      expect(subject.grab(:key, :path)).to be_nil
      expect(result).to be_empty

      subject.set(:key, :path, "value")
      t.map(&:join)

      expect(result.size).to eq(3)
      expect(result).to eq(["value"] * 3)
    end

    it "should delete if value is nil" do
      subject.set(:key, :path, "value")
      expect(subject.is_set?(:key, :path)).to eq(true)
      subject.set(:key, :path, nil)
      expect(subject.is_set?(:key, :path)).to eq(false)
    end

    it "should not delete notifier if waiters exist" do
      result = nil
      t = Thread.new { result = subject.get(:key, :path) }
      expect(subject.is_set?(:key, :path)).to eq(false)

      subject.set(:key, :path, nil)

      expect(subject.is_set?(:key, :path)).to eq(false)
      expect(result).to be_nil

      subject.set(:key, :path, "value")
      t.join

      expect(subject.is_set?(:key, :path)).to eq(true)
      expect(result).to eq("value")
    end
  end
end
