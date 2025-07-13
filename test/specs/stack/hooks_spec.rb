require_relative '../../spec'

describe Bogo::Stack::Hooks do
  let(:stack) { Bogo::Stack.new }
  subject { described_class.new(stack: stack) }

  describe "#initialize" do
    it "should raise TypeError when stack type not provided" do
      expect {
        Bogo::Stack::Hooks.new(stack: :stack)
      }.to raise_error(TypeError)
    end
  end

  describe "#after" do
    it "should raise TypeError if identifier is not callable" do
      expect { subject.after(false) }.to raise_error(TypeError)
    end

    it "should raise TypeError if callable block not provided" do
      expect { subject.after(proc{}) }.to raise_error(TypeError)
    end

    it "should not raise TypeError if symbol is provided" do
      expect(subject.after(:all, &proc{})).to eq(subject)
    end

    it "should add item to #after_entries" do
      s = subject.after_entries.size
      subject.after(:all, &proc{})
      expect(s).to be < subject.after_entries.size
    end

    it "should create a new Entry in #after_entries" do
      id = :all
      block = proc{}
      subject.after(id, &block)
      e = subject.after_entries.last
      expect(e).to be_a(Bogo::Stack::Entry)
      expect(e.identifier).to eq(id)
    end

    it "should freeze updated #after_entries" do
      subject.after(:all, &proc{})
      expect(subject.after_entries).to be_frozen
    end

    it "should raise ApplyError if hooks already applied" do
      subject.apply!
      expect {
        subject.after(:all, &proc{})
      }.to raise_error(Bogo::Stack::Error::ApplyError)
    end

    describe ":all" do
      let(:proc1) { @p1 ||= stack.push(proc{}) }
      let(:proc2) { @p2 ||= stack.push(proc{}) }
      let(:proc3) { @p3 ||= stack.push(proc{}) }

      before do
        proc1
        proc2
        proc3
      end

      it "should add hook before all existing actions" do
        hook_seed = proc{ :hook }
        subject.after(:all, &hook_seed)
        result = subject.apply!
        expect(result.size).to eq(6)
        [proc1, hook_seed, proc2, hook_seed, proc3, hook_seed].each_with_index do |to_check, idx|
          if idx % 2 == 0
            expect(result[idx]).to eq(to_check)
          else
            expect(result[idx].callable).to eq(to_check)
          end
        end
      end
    end
  end

  describe "#before" do
    it "should raise TypeError if identifier is not callable" do
      expect{ subject.before(false) }.to raise_error(TypeError)
    end

    it "should raise TypeError if callable block not provided" do
      expect { subject.before(proc{}) }.to raise_error(TypeError)
    end

    it "should not raise TypeError if symbol is provided" do
      expect(subject.before(:all, &proc{})).to eq(subject)
    end

    it "should add item to #before_entries" do
      s = subject.before_entries.size
      subject.before(:all, &proc{})
      expect(s).to be < subject.before_entries.size
    end

    it "should create a new Entry in #before_entries" do
      id = :all
      block = proc{}
      subject.before(id, &block)
      e = subject.before_entries.last
      expect(e).to be_kind_of(Bogo::Stack::Entry)
      expect(e.identifier).to eq(id)
    end

    it "should freeze updated #before_entries" do
      subject.before(:all, &proc{})
      expect(subject.before_entries).to be_frozen
    end

    it "should raise ApplyError if hooks already applied" do
      subject.apply!
      expect {
        subject.before(:all, &proc{})
      }.to raise_error(Bogo::Stack::Error::ApplyError)
    end

    describe ":all" do
      let(:proc1) { @p1 ||= stack.push(proc{}) }
      let(:proc2) { @p2 ||= stack.push(proc{}) }
      let(:proc3) { @p3 ||= stack.push(proc{}) }

      before do
        proc1
        proc2
        proc3
      end

      it "should add hook before all existing actions" do
        hook = proc{ :hook }
        subject.before(:all, &hook)
        result = subject.apply!
        expect(result.size).to eq(6)
        [hook, proc1, hook, proc2, hook, proc3].each_with_index do |to_check, idx|
          if idx % 2 != 0
            expect(result[idx]).to eq(to_check)
          else
            expect(result[idx].callable).to eq(to_check)
          end
        end
      end
    end
  end

  describe "#prepend" do
    it "should raise TypeError if callable block not provided" do
      expect { subject.prepend }.to raise_error(TypeError)
    end

    it "should add item to #prepend_entries" do
      s = subject.prepend_entries.size
      subject.prepend(&proc{})
      expect(s).to be < subject.prepend_entries.size
    end

    it "should create a new Action in #prepend_entries" do
      block = proc{}
      subject.prepend(&block)
      e = subject.prepend_entries.last
      expect(e).to be_kind_of(Bogo::Stack::Action)
    end

    it "should freeze updated #prepend_entries" do
      subject.prepend(&proc{})
      expect(subject.prepend_entries).to be_frozen
    end

    it "should raise ApplyError if hooks already applied" do
      subject.apply!
      expect {
        subject.prepend(&proc{})
      }.to raise_error(Bogo::Stack::Error::ApplyError)
    end
  end

  describe "#append" do
    it "should raise TypeError if callable block not provided" do
      expect { subject.append }.to raise_error(TypeError)
    end

    it "should add item to #append_entries" do
      s = subject.append_entries.size
      subject.append(&proc{})
      expect(s).to be < subject.append_entries.size
    end

    it "should create a new Action in #append_entries" do
      block = proc{}
      subject.append(&block)
      e = subject.append_entries.last
      expect(e).to be_kind_of(Bogo::Stack::Action)
    end

    it "should freeze updated #append_entries" do
      subject.append(&proc{})
      expect(subject.append_entries).to be_frozen
    end

    it "should raise ApplyError if hooks already applied" do
      subject.apply!
      expect { subject.append(&proc{}) }.to raise_error(Bogo::Stack::Error::ApplyError)
    end
  end

  describe "#applied?" do
    it "should be false when not applied" do
      expect(subject).not_to be_applied
    end

    it "should be true when applied" do
      subject.apply!
      expect(subject).to be_applied
    end
  end

  describe "#apply!" do
    let(:proc1) { proc{} }
    let(:proc2) { proc{} }
    let(:proc3) { proc{} }
    let(:proc4) { proc{} }

    before do
      stack.push(proc1)
      stack.push(proc2)
      stack.push(proc3)
      stack.push(proc4)
    end

    describe "multiple applies" do
      it "should raise ApplyError if already applied" do
        subject.apply!
        expect { subject.apply! }.to raise_error(Bogo::Stack::Error::ApplyError)
      end
    end

    describe "prepending and appending hooks" do
      it "should add hook to top of stack" do
        expected = proc { :hook }
        subject.prepend(&expected)
        result = subject.apply!
        expect(result.size).to eq(5)
        expect(result.first.callable).to eq(expected)
      end

      it "should add hook to bottom of stack" do
        expected = proc { :hook }
        subject.append(&expected)
        result = subject.apply!
        expect(result.size).to eq(5)
        expect(result.last.callable).to eq(expected)
      end

      it "should add hook to top and bottom of stack" do
        expected_top = proc { :top }
        expected_bottom = proc { :bottom }
        subject.prepend(&expected_top)
        subject.append(&expected_bottom)
        result = subject.apply!
        expect(result.size).to eq(6)
        expect(result.first.callable).to eq(expected_top)
        expect(result.last.callable).to eq(expected_bottom)
      end
    end

    describe "before and after hooks" do
      it "should add hook after second action" do
        expected = proc { :hook }
        subject.after(proc2, &expected)
        result = subject.apply!
        expect(result.size).to eq(5)
        expect(result[2].callable).to eq(expected)
      end

      it "should add hook after last action" do
        expected = proc { :hook }
        subject.after(proc4, &expected)
        result = subject.apply!
        expect(result.size).to eq(5)
        expect(result[4].callable).to eq(expected)
      end

      it "should add hook before second action" do
        expected = proc { :hook }
        subject.before(proc2, &expected)
        result = subject.apply!
        expect(result.size).to eq(5)
        expect(result[1].callable).to eq(expected)
      end

      it "should add hook before first action" do
        expected = proc { :hook }
        subject.before(proc1, &expected)
        result = subject.apply!
        expect(result.size).to eq(5)
        expect(result.first.callable).to eq(expected)
      end

      it "should add hook before second action and after third action" do
        expected = proc { :hook }
        subject.before(proc2, &expected)
        subject.after(proc3, &expected)
        result = subject.apply!
        expect(result.size).to eq(6)
        expect(result[1].callable).to eq(expected)
        expect(result[4].callable).to eq(expected)
      end
    end
  end
end
