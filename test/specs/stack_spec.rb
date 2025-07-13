require_relative '../spec'

describe Bogo::Stack do
  describe "#parallelize!" do
    context "when unprepared" do
      it "should enable parallel execution" do
        subject.parallelize!
        expect(subject).to be_parallel
      end
    end

    context "when prepared" do
      before { subject.prepare }

      it "should raise an exception" do
        expect {
          subject.parallelize!
        }.to raise_error(Bogo::Stack::Error::PreparedError)
      end
    end
  end

  describe "#push" do
    context "when unprepared" do
      it "should return an action instance" do
        expect(subject.push {}).to be_a(Bogo::Stack::Action)
      end

      context "when callable is a block" do
        it "adds a new action to the stack" do
          subject.push {}
          expect(subject.actions.size).to eq(1)
        end

        it "appends actions to the stack" do
          proc1 = proc{1}
          proc2 = proc{2}

          subject.push(proc1)
          subject.push(proc2)

          expect(subject.actions.size).to eq(2)
          expect(subject.actions.first.callable).to eq(proc1)
          expect(subject.actions.last.callable).to eq(proc2)
        end
      end

      context "when callable is supported class" do
        let(:klass) do
          Class.new do
            def call
            end
          end
        end

        it "adds a new action to the stack" do
          subject.push(klass)
          expect(subject.actions.size).to eq(1)
        end
      end

      context "when callable is unsupported class" do
        let(:klass) { Class.new }

        it "should raise an error" do
          expect { subject.push(klass) }.to raise_error(ArgumentError)
        end
      end
    end

    context "when prepared" do
      before { subject.prepare }

      it "should raise an exception" do
        expect {
          subject.push {}
        }.to raise_error(Bogo::Stack::Error::PreparedError)
      end
    end
  end

  describe "#unshift" do
    context "when unprepared" do
      it "should return an action instance" do
        expect(subject.unshift {}).to be_a(Bogo::Stack::Action)
      end

      context "when callable is a block" do
        it "adds a new action to the stack" do
          subject.unshift {}
          expect(subject.actions.size).to eq(1)
        end

        it "appends actions to the stack" do
          proc1 = proc{1}
          proc2 = proc{2}

          subject.unshift(proc1)
          subject.unshift(proc2)

          expect(subject.actions.size).to eq(2)
          expect(subject.actions.first.callable).to eq(proc2)
          expect(subject.actions.last.callable).to eq(proc1)
        end
      end

      context "when callable is supported class" do
        let(:klass) do
          Class.new do
            def call
            end
          end
        end

        it "adds a new action to the stack" do
          subject.unshift(klass)
          expect(subject.actions.size).to eq(1)
        end
      end

      context "when callable is unsupported class" do
        let(:klass) { Class.new }

        it "should raise an error" do
          expect { subject.unshift(klass) }.to raise_error(ArgumentError)
        end
      end
    end

    context "when prepared" do
      before { subject.prepare }

      it "should raise an exception" do
        expect {
          subject.unshift {}
        }.to raise_error(Bogo::Stack::Error::PreparedError)
      end
    end
  end

  describe "#remove" do
    it "removes action at given index" do
      actions = 3.times.map do
        subject.push {}
      end
      expect(subject.actions.size).to eq(3)
      actions.each_with_index do |act, idx|
        expect(subject.actions[idx]).to eq(act)
      end

      subject.remove(1)
      expect(subject.actions.size).to eq(2)
      expect(subject.actions.first).to eq(actions.first)
      expect(subject.actions.last).to eq(actions.last)
    end

    it "removes given action" do
      actions = 3.times.map do
        subject.push {}
      end
      expect(subject.actions.size).to eq(3)
      actions.each_with_index do |act, idx|
        expect(subject.actions[idx]).to eq(act)
      end

      subject.remove(actions[1])
      expect(subject.actions.size).to eq(2)
      expect(subject.actions.first).to eq(actions.first)
      expect(subject.actions.last).to eq(actions.last)
    end

    it "returns the removed action" do
      act = subject.push {}
      removed = subject.remove(0)
      expect(removed).to eq(act)
    end

    context "when prepared" do
      before { subject.prepare }

      it "should raise an exception" do
        expect {
          subject.remove(0)
        }.to raise_error(Bogo::Stack::Error::PreparedError)
      end
    end
  end

  describe "#pop" do
    it "should return nil when empty" do
      expect(subject.pop).to be_nil
    end

    it "should return last action" do
      3.times { subject.push {} }
      check = subject.actions.last
      expect(subject.pop).to eq(check)
    end

    it "should remove action from stack" do
      3.times { subject.push {} }
      expect(subject.size).to eq(3)
      check = subject.pop
      expect(subject.size).to eq(2)
      expect(subject.actions).not_to include(check)
    end

    context "when prepared" do
      before { subject.prepare }

      it "should raise an exception" do
        expect {
          subject.pop
        }.to raise_error(Bogo::Stack::Error::PreparedError)
      end
    end
  end

  describe "#shift" do
    it "should return nil when empty" do
      expect(subject.shift).to be_nil
    end

    it "should return first action" do
      3.times { subject.push {} }
      check = subject.actions.first
      expect(subject.shift).to eq(check)
    end

    it "should remove action from stack" do
      3.times { subject.push {} }
      expect(subject.size).to eq(3)
      check = subject.shift
      expect(subject.size).to eq(2)
      expect(subject.actions).not_to include(check)
    end

    context "when prepared" do
      before { subject.prepare }

      it "should raise an exception" do
        expect {
          subject.shift
        }.to raise_error(Bogo::Stack::Error::PreparedError)
      end
    end
  end

  describe "#prepared?" do
    it "should be false when not prepared" do
      expect(subject).not_to be_prepared
    end

    it "should be true when prepared" do
      subject.prepare
      expect(subject).to be_prepared
    end
  end

  describe "#size" do
    it "should be zero when no actions registered" do
      expect(subject.size).to eq(0)
    end

    it "should match the size of the actions" do
      4.times { subject.push {} }
      expect(subject.size).to eq(subject.actions.size)
    end
  end

  describe "#prepare" do
    it "should prepare an empty stack" do
      subject.prepare
      expect(subject).to be_prepared
    end

    it "should prepare populated stack" do
      3.times { subject.push {} }
      subject.prepare
      expect(subject).to be_prepared
    end

    it "should prepare all actions" do
      3.times { subject.push {} }
      subject.prepare
      subject.actions.each do |action|
        expect(action).to be_prepared
      end
    end

    context "when prepared" do
      before { subject.prepare }

      it "should raise an exception" do
        expect {
          subject.prepare
        }.to raise_error(Bogo::Stack::Error::PreparedError)
      end
    end
  end

  describe "#call" do
    context "when not prepared" do
      it "should raise an error" do
        expect { subject.call }.to raise_error(Bogo::Stack::Error::UnpreparedError)
      end
    end

    it "should mark stack complete" do
      subject.prepare
      subject.call
      expect(subject).to be_complete
    end

    it "should not be failed" do
      subject.prepare
      subject.call
      expect(subject).not_to be_failed
    end

    it "should call all registered actions" do
      results = []
      5.times { |i| subject.push { results << i } }
      subject.prepare
      subject.call
      expect(results).to eq([0,1,2,3,4])
    end

    it "should mark stack as started" do
      subject.prepare
      subject.call
      expect(subject).to be_started
    end

    context "with context" do
      it "should update value in context" do
        subject.push { |context:| context.set(:value, 1) }
        3.times { subject.push { |context:| context.set(:value, context.get(:value) + 1) } }
        subject.prepare
        subject.call
        expect(subject).not_to be_failed
        expect(subject.context.is_set?(:value)).to be_truthy
        expect(subject.context.get(:value)).to eq(4)
      end

      context "when failure encountered" do
        before do
          subject.push { |context:| context.set(:value, 1) }
          subject.push { raise "test error" }
        end

        it "should complete without exception" do
          subject.prepare
          expect { subject.call }.not_to raise_error
        end

        it "should mark context as failed" do
          subject.prepare
          subject.call
          expect(subject.context).to be_failed
        end

        it "should show stack as failed" do
          subject.prepare
          subject.call
          expect(subject).to be_failed
        end

        it "should show stack as complete" do
          subject.prepare
          subject.call
          expect(subject).to be_complete
        end

        context "with recovery" do
          before do
            subject.actions.last.set_recovery do |context, arguments|
              context.set(:recovery_executed, true)
            end
          end

          it "should call the failed action recovery" do
            subject.prepare
            subject.call
            expect(subject.context.is_set?(:recovery_executed)).to be_truthy
            expect(subject.context.get(:recovery_executed)).to be_truthy
          end

          context "with recovery on all actions" do
            before do
              subject.actions.first.set_recovery do |context, arguments|
                context.set(:first_recovery_executed, true)
              end
            end

            it "should call recovery on all actions" do
              subject.prepare
              subject.call
              [:first_recovery_executed, :recovery_executed].each do |key|
                expect(subject.context.is_set?(key)).to be_truthy
                expect(subject.context.get(key)).to be_truthy
              end
            end
          end
        end
      end
    end

    context "#parallelize" do
      before { subject.parallelize! }

      it "should call all registered actions" do
        results = []
        5.times { |i| subject.push { results << i } }
        subject.prepare
        subject.call
        expect(results.sort).to eq([0,1,2,3,4])
      end
    end
  end
end
