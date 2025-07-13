require_relative '../../spec'

describe Bogo::Stack::Action do
  let(:described_class) { Bogo::Stack::Action }
  let(:callable) { proc{} }
  let(:arguments) { [] }
  let(:stack) { Bogo::Stack.new }

  let(:subject) { described_class.new(stack: stack, callable: callable) }

  it "should reference the stack" do
    expect(subject.stack).to eq(stack)
  end

  it "should have set the callable" do
    expect(subject.callable).to eq(callable)
  end

  describe "when no block or callable is provided" do
    it "should raise argument error" do
      expect { described_class.new(stack: stack) }.to raise_error(ArgumentError)
    end
  end

  describe "when both block and callable are provided" do
    it "should raise argument error" do
      expect { described_class.new(stack: stack, callable: callable){} }.to raise_error(ArgumentError)
    end
  end

  describe "when stack value provided is not a stack" do
    it "should raise type error" do
      expect { described_class.new(stack: :stack, callable: callable) }.to raise_error(TypeError)
    end
  end

  describe "#with" do
    let(:arguments) { [1, 2] }

    it "should set the arguments for the action" do
      subject.with(*arguments)
      expect(subject.arguments).to eq(arguments)
    end

    it "should set the arguments after they have already been set" do
      subject.with(*arguments)
      expect(subject.arguments).to eq(arguments)
      new_args = [3, 4]
      subject.with(*new_args)
      expect(subject.arguments).to eq(new_args)
    end

    describe "after action has been prepared" do
      before { subject.prepare }

      it "should error" do
        expect { subject.with(*arguments) }.to raise_error(Bogo::Stack::Error::PreparedError)
      end
    end
  end

  describe "#prepare" do
    it "should freeze callable" do
      subject.prepare
      expect(subject.callable).to be_frozen
    end

    it "should freeze arguments" do
      subject.prepare
      expect(subject.arguments).to be_frozen
    end

    it "should error if already prepared" do
      subject.prepare
      expect { subject.prepare }.to raise_error(Bogo::Stack::Error::PreparedError)
    end

    describe "callable does not respond to #call" do
      let(:callable) { :symbol }

      it "should raise error" do
        expect { subject.prepare }.to raise_error(ArgumentError)
      end
    end

    describe "callable is a custom class with #call method" do
      let(:callable) {  Class.new { def call; end; } }

      it "should set callable to instance of custom class" do
        subject.prepare
        expect(subject.callable.is_a?(callable)).to eq(true)
      end
    end

    describe "callable is a custom class without #call method" do
      let(:callable) { Class.new }

      it "should raise an error" do
        expect { subject.prepare }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#called?" do
    it "should be false when not called" do
      expect(subject).not_to be_called
    end

    it "should be true after being called" do
      stack.prepare && subject.prepare
      subject.call
      expect(subject).to be_called
    end
  end

  describe "#call" do
    let(:callable) { proc{ @call_value = :set } }

    before do
      @call_value = nil
      stack.prepare
    end

    it "should raise error when not prepared" do
      expect { subject.call }.to raise_error(Bogo::Stack::Error::PreparedError)
    end

    describe "when action is prepared" do
      before { subject.prepare }

      it "should update call value when called" do
        expect(@call_value).to be_nil
        subject.call
        expect(@call_value).to eq(:set)
      end
    end
  end
end
