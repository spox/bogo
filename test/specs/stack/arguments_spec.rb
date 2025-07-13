require_relative '../../spec'

describe Bogo::Stack::Action::Arguments do
  describe "#new" do
    it "raises error if list is not an array" do
      expect{ described_class.new(list: :symbol) }.to raise_error(TypeError)
    end

    it "raises error if named is not a hash" do
      expect { described_class.new(named: :symbol) }.to raise_error(TypeError)
    end

    it "defaults the list value" do
      expect(described_class.new.list).to eq([])
    end

    it "defaults the named value" do
      expect(described_class.new.named).to eq({})
    end

    it "sets the list value" do
      val = [:list, :value]
      expect(described_class.new(list: val).list).to eq(val)
    end

    it "sets the named value" do
      val = {named: :value}
      expect(described_class.new(named: val).named).to eq(val)
    end

    it "converts named value keys to symbols" do
      val = {"named" => :value}
      expect(described_class.new(named: val).named).to eq({named: :value})
    end
  end

  describe ".load" do
    let(:callable) { proc{|arg1, arg2|} }

    it "should not include named arguments" do
      subject = described_class.
        load(callable: callable, arguments: [:fubar, {hash: :value}])
      expect(subject.named).to eq({})
    end

    it "should set the list argument" do
      subject = described_class.
        load(callable: callable, arguments: [:fubar, {hash: :value}])
      expect(subject.list).to eq([:fubar, {hash: :value}])
    end

    describe "when callable has named arguments" do
      let(:callable) { proc{|arg1, param:|} }

      it "should set list without named argument" do
        subject = described_class.
          load(callable: callable, arguments: [:fubar, {param: :value}])
        expect(subject.list).to eq([:fubar])
      end

      it "should set named argument" do
        subject = described_class.
          load(callable: callable, arguments: [:fubar, {param: :value}])
        expect(subject.named).to eq({param: :value})
      end

      it "should not set named argument if extra names provided" do
        subject = described_class.
          load(callable: callable, arguments: [:fubar, {param: :value, param2: :value}])
        expect(subject.named).to eq({param: :value})
        expect(subject.list).to eq([:fubar])
      end
    end
  end

  describe "#validate!" do
    let(:list) { [] }
    let(:named) { {} }
    let(:subject) { described_class.new(list: list, named: named) }
    let(:callable) { proc{} }

    it "should properly validate when no parameters are required" do
      expect(subject.validate!(callable)).to be_nil
    end

    describe "when parameter list required" do
      let(:callable) { lambda{|arg1, arg2|} }

      it "should raise invalid arguments error" do
        expect { subject.validate!(callable) }.to raise_error(Bogo::Stack::Error::InvalidArgumentsError)
      end

      describe "when correct number of arguments provided" do
        let(:list) { [1, 2] }

        it "should properly validate" do
          expect(subject.validate!(callable)).to be_nil
        end
      end

      describe "when fewer than required arguments provided" do
        let(:list) { [1] }

        it "should raise invalid arguments error" do
          expect { subject.validate!(callable) }.to raise_error(Bogo::Stack::Error::InvalidArgumentsError)
        end
      end

      describe "when more than required parameters provided" do
        let(:list) { [1, 2, 3] }

        it "should raise invalid arguments error" do
          expect { subject.validate!(callable) }.to raise_error(Bogo::Stack::Error::InvalidArgumentsError)
        end
      end
    end

    describe "when parameter list is optional" do
      let(:callable) { lambda{|arg1=nil, arg2=nil|} }

      it "should properly validate when no arguments provided" do
        expect(subject.validate!(callable)).to be_nil
      end

      describe "when one one argument is provided" do
        let(:list) { [1] }

        it "should properly validate" do
          expect(subject.validate!(callable)).to be_nil
        end
      end

      describe "when all arguments are provided" do
        let(:list) { [1, 2] }

        it "should properly validate" do
          expect(subject.validate!(callable)).to be_nil
        end
      end

      describe "when extra arguments are provided" do
        let(:list) { [1, 2, 3] }

        it "should raise invalid arguments error" do
          expect{ subject.validate!(callable) }.to raise_error(Bogo::Stack::Error::InvalidArgumentsError)
        end
      end
    end

    describe "when named parameters required" do
      let(:callable) { lambda{|arg1:, arg2:|} }

      it "should raise invalid arguments error" do
        expect { subject.validate!(callable) }.to raise_error(Bogo::Stack::Error::InvalidArgumentsError)
      end

      describe "when correct number of arguments provided" do
        let(:named) { {arg1: 1, arg2: 2} }

        it "should properly validate" do
          expect(subject.validate!(callable)).to be_nil
        end
      end

      describe "when fewer than required arguments provided" do
        let(:named) { {arg1: 1} }

        it "should raise invalid arguments error" do
          expect { subject.validate!(callable) }.to raise_error(Bogo::Stack::Error::InvalidArgumentsError)
        end
      end

      describe "when more than required parameters provided" do
        let(:named) { {arg1: 1, arg2: 2, arg3: 3} }

        it "should raise invalid arguments error" do
          expect { subject.validate!(callable) }.to raise_error(Bogo::Stack::Error::InvalidArgumentsError)
        end
      end
    end

    describe "when named parameters are optional" do
      let(:callable) { lambda{|arg1: nil, arg2: nil|} }

      it "should properly validate when no arguments provided" do
        expect(subject.validate!(callable)).to be_nil
      end

      describe "when one one argument is provided" do
        let(:named) { {arg1: 1} }

        it "should properly validate" do
          expect(subject.validate!(callable)).to be_nil
        end
      end

      describe "when all arguments are provided" do
        let(:named) { {arg1: 1, arg2: 2} }

        it "should properly validate" do
          expect(subject.validate!(callable)).to be_nil
        end
      end

      describe "when extra arguments are provided" do
        let(:named) { {arg1: 1, arg2: 2, arg3: 3} }

        it "should raise invalid arguments error" do
          expect { subject.validate!(callable) }.to raise_error(Bogo::Stack::Error::InvalidArgumentsError)
        end
      end
    end
  end
end
