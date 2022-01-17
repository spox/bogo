require_relative '../spec'

describe Bogo::Stack::Hooks do
  let(:stack) { Bogo::Stack.new }
  let(:subject) { Bogo::Stack::Hooks.new(stack: stack) }

  describe "#initialize" do
    it "should raise TypeError when stack type not provided" do
      _(->{ Bogo::Stack::Hooks.new(stack: :stack) }).must_raise TypeError
    end
  end

  describe "#after" do
    it "should raise TypeError if identifier is not callable" do
      _(->{ subject.after(false) }).must_raise TypeError
    end

    it "should raise TypeError if callable block not provided" do
      _(->{ subject.after(proc{}) }).must_raise TypeError
    end

    it "should not raise TypeError if symbol is provided" do
      _(subject.after(:all, &proc{})).must_equal subject
    end

    it "should add item to #after_entries" do
      s = subject.after_entries.size
      subject.after(:all, &proc{})
      _(s).must_be :<, subject.after_entries.size
    end

    it "should create a new Entry in #after_entries" do
      id = :all
      block = proc{}
      subject.after(id, &block)
      e = subject.after_entries.last
      _(e).must_be_kind_of Bogo::Stack::Entry
      _(e.identifier).must_equal id
    end

    it "should freeze updated #after_entries" do
      subject.after(:all, &proc{})
      _(subject.after_entries).must_be :frozen?
    end

    it "should raise ApplyError if hooks already applied" do
      subject.apply!
      _(->{ subject.after(:all, &proc{}) }).must_raise Bogo::Stack::Error::ApplyError
    end

    describe ":all" do
      let(:proc1) { proc{} }
      let(:proc2) { proc{} }
      let(:proc3) { proc{} }

      before do
        stack.push(proc1)
        stack.push(proc2)
        stack.push(proc3)
      end

      it "should add hook before all existing actions" do
        hook = proc{ :hook }
        subject.after(:all, &hook)
        result = subject.apply!
        _(result.size).must_equal 6
        _(result[0].callable).must_equal proc1
        _(result[1].callable).must_equal hook
        _(result[2].callable).must_equal proc2
        _(result[3].callable).must_equal hook
        _(result[4].callable).must_equal proc3
        _(result[5].callable).must_equal hook
      end
    end
  end

  describe "#before" do
    let(:subject) { Bogo::Stack::Hooks.new(stack: stack) }

    it "should raise TypeError if identifier is not callable" do
      _(->{ subject.before(false) }).must_raise TypeError
    end

    it "should raise TypeError if callable block not provided" do
      _(->{ subject.before(proc{}) }).must_raise TypeError
    end

    it "should not raise TypeError if symbol is provided" do
      _(subject.before(:all, &proc{})).must_equal subject
    end

    it "should add item to #before_entries" do
      s = subject.before_entries.size
      subject.before(:all, &proc{})
      _(s).must_be :<, subject.before_entries.size
    end

    it "should create a new Entry in #before_entries" do
      id = :all
      block = proc{}
      subject.before(id, &block)
      e = subject.before_entries.last
      _(e).must_be_kind_of Bogo::Stack::Entry
      _(e.identifier).must_equal id
    end

    it "should freeze updated #before_entries" do
      subject.before(:all, &proc{})
      _(subject.before_entries).must_be :frozen?
    end

    it "should raise ApplyError if hooks already applied" do
      subject.apply!
      _(->{ subject.before(:all, &proc{}) }).must_raise Bogo::Stack::Error::ApplyError
    end

    describe ":all" do
      let(:proc1) { proc{} }
      let(:proc2) { proc{} }
      let(:proc3) { proc{} }

      before do
        stack.push(proc1)
        stack.push(proc2)
        stack.push(proc3)
      end

      it "should add hook before all existing actions" do
        hook = proc{ :hook }
        subject.before(:all, &hook)
        result = subject.apply!
        _(result.size).must_equal 6
        _(result[0].callable).must_equal hook
        _(result[1].callable).must_equal proc1
        _(result[2].callable).must_equal hook
        _(result[3].callable).must_equal proc2
        _(result[4].callable).must_equal hook
        _(result[5].callable).must_equal proc3
      end
    end
  end

  describe "#prepend" do
    let(:subject) { Bogo::Stack::Hooks.new(stack: stack) }

    it "should raise TypeError if callable block not provided" do
      _(->{ subject.prepend }).must_raise TypeError
    end

    it "should add item to #prepend_entries" do
      s = subject.prepend_entries.size
      subject.prepend(&proc{})
      _(s).must_be :<, subject.prepend_entries.size
    end

    it "should create a new Action in #prepend_entries" do
      block = proc{}
      subject.prepend(&block)
      e = subject.prepend_entries.last
      _(e).must_be_kind_of Bogo::Stack::Action
    end

    it "should freeze updated #prepend_entries" do
      subject.prepend(&proc{})
      _(subject.prepend_entries).must_be :frozen?
    end

    it "should raise ApplyError if hooks already applied" do
      subject.apply!
      _(->{ subject.prepend(&proc{}) }).must_raise Bogo::Stack::Error::ApplyError
    end
  end

  describe "#append" do
    it "should raise TypeError if callable block not provided" do
      _(->{ subject.append }).must_raise TypeError
    end

    it "should add item to #append_entries" do
      s = subject.append_entries.size
      subject.append(&proc{})
      _(s).must_be :<, subject.append_entries.size
    end

    it "should create a new Action in #append_entries" do
      block = proc{}
      subject.append(&block)
      e = subject.append_entries.last
      _(e).must_be_kind_of Bogo::Stack::Action
    end

    it "should freeze updated #append_entries" do
      subject.append(&proc{})
      _(subject.append_entries).must_be :frozen?
    end

    it "should raise ApplyError if hooks already applied" do
      subject.apply!
      _(->{ subject.append(&proc{}) }).must_raise Bogo::Stack::Error::ApplyError
    end
  end

  describe "#applied?" do
    it "should be false when not applied" do
      _(subject.applied?).must_equal false
    end

    it "should be true when applied" do
      subject.apply!
      _(subject.applied?).must_equal true
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
        _(->{ subject.apply! }).must_raise Bogo::Stack::Error::ApplyError
      end
    end

    describe "prepending and appending hooks" do
      it "should add hook to top of stack" do
        expected = proc { :hook }
        subject.prepend(&expected)
        result = subject.apply!
        _(result.size).must_equal 5
        _(result.first.callable).must_equal expected
      end

      it "should add hook to bottom of stack" do
        expected = proc { :hook }
        subject.append(&expected)
        result = subject.apply!
        _(result.size).must_equal 5
        _(result.last.callable).must_equal expected
      end

      it "should add hook to top and bottom of stack" do
        expected_top = proc { :top }
        expected_bottom = proc { :bottom }
        subject.prepend(&expected_top)
        subject.append(&expected_bottom)
        result = subject.apply!
        _(result.size).must_equal 6
        _(result.first.callable).must_equal expected_top
        _(result.last.callable).must_equal expected_bottom
      end
    end

    describe "before and after hooks" do
      it "should add hook after second action" do
        expected = proc { :hook }
        subject.after(proc2, &expected)
        result = subject.apply!
        _(result.size).must_equal 5
        _(result[2].callable).must_equal expected
      end

      it "should add hook after last action" do
        expected = proc { :hook }
        subject.after(proc4, &expected)
        result = subject.apply!
        _(result.size).must_equal 5
        _(result[4].callable).must_equal expected
      end

      it "should add hook before second action" do
        expected = proc { :hook }
        subject.before(proc2, &expected)
        result = subject.apply!
        _(result.size).must_equal 5
        _(result[1].callable).must_equal expected
      end

      it "should add hook before first action" do
        expected = proc { :hook }
        subject.before(proc1, &expected)
        result = subject.apply!
        _(result.size).must_equal 5
        _(result[0].callable).must_equal expected
      end

      it "should add hook before second action and after third action" do
        expected = proc { :hook }
        subject.before(proc2, &expected)
        subject.after(proc3, &expected)
        result = subject.apply!
        _(result.size).must_equal 6
        _(result[1].callable).must_equal expected
        _(result[4].callable).must_equal expected
      end
    end
  end
end

describe Bogo::Stack::Context do
  let(:stack) { Bogo::Stack.new }
  let(:subject) { Bogo::Stack::Context.new(stack: stack) }

  describe "#stacks" do
    it "should have initial stack in list" do
      _(subject.stacks).must_include stack
    end

    it "should be frozen" do
      _(subject.stacks).must_be :frozen?
    end

    it "should only include initial stack" do
      _(subject.stacks).must_equal [stack]
    end
  end

  describe "#for" do
    let(:stack2) { Bogo::Stack.new }

    it "should add new stack to the list" do
      subject.for(stack2)
      _(subject.stacks).must_include(stack)
      _(subject.stacks).must_include(stack2)
    end

    it "should freeze list after modifying" do
      subject.for(stack2)
      _(subject.stacks).must_be :frozen?
    end

    it "should return self" do
      _(subject.for(stack2)).must_equal subject
    end
  end

  describe "#is_set?" do
    it "should return true if value has been set" do
      subject.set(:key, :path, "value")
      _(subject.is_set?(:key, :path)).must_equal true
    end

    it "should return false if value has not been set" do
      _(subject.is_set?(:key, :path)).must_equal false
    end
  end

  describe "#get" do
    it "should return value when set" do
      subject.set(:key, :path, "value")
      _(subject.get(:key, :path)).must_equal "value"
    end

    it "should wait for value when not set" do
      result = nil
      t_get = Thread.new { result = subject.get(:key, :path) }

      _(subject.is_set?(:key, :path)).must_equal false
      _(result).must_be_nil

      t_set = Thread.new { subject.set(:key, :path, "value") }
      t_set.join

      _(subject.is_set?(:key, :path)).must_equal true

      t_get.join

      _(result).must_equal("value")
    end
  end

  describe "#grab" do
    it "should return value when set" do
      subject.set(:key, :path, "value")
      _(subject.grab(:key, :path)).must_equal "value"
    end

    it "should return nil when value is unset" do
      _(subject.grab(:key, :path)).must_be_nil
    end
  end

  describe "#set" do
    it "should set value" do
      subject.set(:key, :path, "value")
      _(subject.grab(:key, :path)).must_equal "value"
    end

    it "should notify all waiters when setting value" do
      result = []
      t = []
      t << Thread.new { result << subject.get(:key, :path) }
      t << Thread.new { result << subject.get(:key, :path) }
      t << Thread.new { result << subject.get(:key, :path) }

      _(subject.grab(:key, :path)).must_be_nil
      _(result).must_be :empty?

      subject.set(:key, :path, "value")
      t.map(&:join)

      _(result.size).must_equal 3
      _(result).must_equal ["value"] * 3
    end

    it "should delete if value is nil" do
      subject.set(:key, :path, "value")
      _(subject.is_set?(:key, :path)).must_equal true
      subject.set(:key, :path, nil)
      _(subject.is_set?(:key, :path)).must_equal false
    end

    it "should not delete notifier if waiters exist" do
      result = nil
      t = Thread.new { result = subject.get(:key, :path) }
      _(subject.is_set?(:key, :path)).must_equal false

      subject.set(:key, :path, nil)

      _(subject.is_set?(:key, :path)).must_equal false
      _(result).must_be_nil

      subject.set(:key, :path, "value")
      t.join

      _(subject.is_set?(:key, :path)).must_equal true
      _(result).must_equal "value"
    end
  end
end

describe Bogo::Stack::Action::Arguments do
  let(:described_class) { Bogo::Stack::Action::Arguments }

  describe "#new" do
    it "raises error if list is not an array" do
      _{ described_class.new(list: :symbol) }.must_raise TypeError
    end

    it "raises error if named is not a hash" do
      _{ described_class.new(named: :symbol) }.must_raise TypeError
    end

    it "defaults the list value" do
      _(described_class.new.list).must_equal []
    end

    it "defaults the named value" do
      _(described_class.new.named).must_equal({})
    end

    it "sets the list value" do
      val = [:list, :value]
      _(described_class.new(list: val).list).must_equal val
    end

    it "sets the named value" do
      val = {named: :value}
      _(described_class.new(named: val).named).must_equal val
    end

    it "converts named value keys to symbols" do
      val = {"named" => :value}
      _(described_class.new(named: val).named).must_equal({named: :value})
    end
  end

  describe ".load" do
    let(:callable) { proc{|arg1, arg2|} }

    it "should not include named arguments" do
      subject = described_class.
        load(callable: callable, arguments: [:fubar, {hash: :value}])
      _(subject.named).must_equal({})
    end

    it "should set the list argument" do
      subject = described_class.
        load(callable: callable, arguments: [:fubar, {hash: :value}])
      _(subject.list).must_equal [:fubar, {hash: :value}]
    end

    describe "when callable has named arguments" do
      let(:callable) { proc{|arg1, param:|} }

      it "should set list without named argument" do
        subject = described_class.
          load(callable: callable, arguments: [:fubar, {param: :value}])
        _(subject.list).must_equal [:fubar]
      end

      it "should set named argument" do
        subject = described_class.
          load(callable: callable, arguments: [:fubar, {param: :value}])
        _(subject.named).must_equal({param: :value})
      end

      it "should not set named argument if extra names provided" do
        subject = described_class.
          load(callable: callable, arguments: [:fubar, {param: :value, param2: :value}])
        _(subject.named).must_equal({})
        _(subject.list).must_equal [:fubar, {param: :value, param2: :value}]
      end
    end
  end

  describe "#validate!" do
    let(:list) { [] }
    let(:named) { {} }
    let(:subject) { described_class.new(list: list, named: named) }
    let(:callable) { proc{} }

    it "should properly validate when no parameters are required" do
      _(subject.validate!(callable)).must_be_nil
    end

    describe "when parameter list required" do
      let(:callable) { lambda{|arg1, arg2|} }

      it "should raise invalid arguments error" do
        _{ subject.validate!(callable) }.must_raise Bogo::Stack::Error::InvalidArgumentsError
      end

      describe "when correct number of arguments provided" do
        let(:list) { [1, 2] }

        it "should properly validate" do
          _(subject.validate!(callable)).must_be_nil
        end
      end

      describe "when fewer than required arguments provided" do
        let(:list) { [1] }

        it "should raise invalid arguments error" do
          _{ subject.validate!(callable) }.must_raise Bogo::Stack::Error::InvalidArgumentsError
        end
      end

      describe "when more than required parameters provided" do
        let(:list) { [1, 2, 3] }

        it "should raise invalid arguments error" do
          _{ subject.validate!(callable) }.must_raise Bogo::Stack::Error::InvalidArgumentsError
        end
      end
    end

    describe "when parameter list is optional" do
      let(:callable) { lambda{|arg1=nil, arg2=nil|} }

      it "should properly validate when no arguments provided" do
        _(subject.validate!(callable)).must_be_nil
      end

      describe "when one one argument is provided" do
        let(:list) { [1] }

        it "should properly validate" do
          _(subject.validate!(callable)).must_be_nil
        end
      end

      describe "when all arguments are provided" do
        let(:list) { [1, 2] }

        it "should properly validate" do
          _(subject.validate!(callable)).must_be_nil
        end
      end

      describe "when extra arguments are provided" do
        let(:list) { [1, 2, 3] }

        it "should raise invalid arguments error" do
          _{ subject.validate!(callable) }.must_raise Bogo::Stack::Error::InvalidArgumentsError
        end
      end
    end

    describe "when named parameters required" do
      let(:callable) { lambda{|arg1:, arg2:|} }

      it "should raise invalid arguments error" do
        _{ subject.validate!(callable) }.must_raise Bogo::Stack::Error::InvalidArgumentsError
      end

      describe "when correct number of arguments provided" do
        let(:named) { {arg1: 1, arg2: 2} }

        it "should properly validate" do
          _(subject.validate!(callable)).must_be_nil
        end
      end

      describe "when fewer than required arguments provided" do
        let(:named) { {arg1: 1} }

        it "should raise invalid arguments error" do
          _{ subject.validate!(callable) }.must_raise Bogo::Stack::Error::InvalidArgumentsError
        end
      end

      describe "when more than required parameters provided" do
        let(:named) { {arg1: 1, arg2: 2, arg3: 3} }

        it "should raise invalid arguments error" do
          _{ subject.validate!(callable) }.must_raise Bogo::Stack::Error::InvalidArgumentsError
        end
      end
    end

    describe "when named parameters are optional" do
      let(:callable) { lambda{|arg1: nil, arg2: nil|} }

      it "should properly validate when no arguments provided" do
        _(subject.validate!(callable)).must_be_nil
      end

      describe "when one one argument is provided" do
        let(:named) { {arg1: 1} }

        it "should properly validate" do
          _(subject.validate!(callable)).must_be_nil
        end
      end

      describe "when all arguments are provided" do
        let(:named) { {arg1: 1, arg2: 2} }

        it "should properly validate" do
          _(subject.validate!(callable)).must_be_nil
        end
      end

      describe "when extra arguments are provided" do
        let(:named) { {arg1: 1, arg2: 2, arg3: 3} }

        it "should raise invalid arguments error" do
          _{ subject.validate!(callable) }.must_raise Bogo::Stack::Error::InvalidArgumentsError
        end
      end
    end
  end
end

describe Bogo::Stack::Action do
  let(:described_class) { Bogo::Stack::Action }
  let(:callable) { proc{} }
  let(:arguments) { [] }
  let(:stack) { Bogo::Stack.new }

  let(:subject) { described_class.new(stack: stack, callable: callable) }

  it "should reference the stack" do
    _(subject.stack).must_equal stack
  end

  it "should have set the callable" do
    _(subject.callable).must_equal callable
  end

  describe "when no block or callable is provided" do
    it "should raise argument error" do
      _{ described_class.new(stack: stack) }.must_raise ArgumentError
    end
  end

  describe "when both block and callable are provided" do
    it "should raise argument error" do
      _{ described_class.new(stack: stack, callable: callable){} }.must_raise ArgumentError
    end
  end

  describe "when stack value provided is not a stack" do
    it "should raise type error" do
      _{ described_class.new(stack: :stack, callable: callable) }.must_raise TypeError
    end
  end

  describe "#with" do
    let(:arguments) { [1, 2] }

    it "should set the arguments for the action" do
      subject.with(*arguments)
      _(subject.arguments).must_equal arguments
    end

    it "should set the arguments after they have already been set" do
      subject.with(*arguments)
      _(subject.arguments).must_equal arguments
      new_args = [3, 4]
      subject.with(*new_args)
      _(subject.arguments).must_equal new_args
    end

    describe "after action has been prepared" do
      before { subject.prepare }

      it "should error" do
        _{ subject.with(*arguments) }.must_raise Bogo::Stack::Error::PreparedError
      end
    end
  end

  describe "#prepare" do
    it "should freeze callable" do
      subject.prepare
      _(subject.callable).must_be :frozen?
    end

    it "should freeze arguments" do
      subject.prepare
      _(subject.arguments).must_be :frozen?
    end

    it "should error if already prepared" do
      subject.prepare
      _{ subject.prepare }.must_raise Bogo::Stack::Error::PreparedError
    end

    describe "callable does not respond to #call" do
      let(:callable) { :symbol }

      it "should raise error" do
        _{ subject.prepare }.must_raise ArgumentError
      end
    end

    describe "callable is a custom class with #call method" do
      let(:callable) {  Class.new { def call; end; } }

      it "should set callable to instance of custom class" do
        subject.prepare
        _(subject.callable.is_a?(callable)).must_equal true
      end
    end

    describe "callable is a custom class without #call method" do
      let(:callable) { Class.new }

      it "should raise an error" do
        _{ subject.prepare }.must_raise ArgumentError
      end
    end
  end

  describe "#called?" do
    it "should be false when not called" do
      _(subject.called?).must_equal false
    end

    it "should be true after being called" do
      stack.prepare && subject.prepare
      subject.call
      _(subject.called?).must_equal true
    end
  end

  describe "#call" do
    let(:callable) { proc{ @call_value = :set } }

    before do
      @call_value = nil
      stack.prepare
    end

    it "should raise error when not prepared" do
      _{ subject.call }.must_raise Bogo::Stack::Error::PreparedError
    end

    describe "when action is prepared" do
      before { subject.prepare }

      it "should update call value when called" do
        _(@call_value).must_be_nil
        subject.call
        _(@call_value).must_equal :set
      end
    end
  end
end
