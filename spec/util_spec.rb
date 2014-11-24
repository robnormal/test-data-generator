require "rspec"
require_relative "../lib/util"

describe "util" do
  describe HashAppendable do
    describe :<< do
      it 'appends the given key,value pair to itself' do
        h = HashAppendable.new
        h << [:a, 'alpha']

        expect(h.length).to eq(1)
        expect(h[:a]).to eq('alpha')
      end
    end
  end

  describe Maybe do
    describe 'Maybe.just' do
      it 'stores a value in a Maybe' do
        expect(Maybe.just(3)).to be_a(Maybe)
      end
    end

    describe 'Maybe.nothing' do
      it 'produces an empty Maybe' do
        expect(Maybe.nothing).to be_a(Maybe)
      end
    end

    describe :nothing? do
      it 'returns is true iff the Maybe is empty' do
        expect(Maybe.just(3).nothing?).to be false
        expect(Maybe.nothing.nothing?).to be true
      end
    end

    describe :from_just do
      it 'retrieves value stored with Maybe.just' do
        expect(Maybe.just(3).from_just).to be 3
      end

      it 'raises an error if it is empty' do
        expect { Maybe.nothing.from_just }.to raise_error
      end
    end

    describe :== do
      it 'compares Maybes in the obvious way' do
        expect(Maybe.nothing).to eq(Maybe.nothing)
        expect(Maybe.just(8)).to eq(Maybe.just(8))
      end
    end

    describe :fmap do
      it 'just(x) to just(f(x))' do
        expect(Maybe.just('abcd').fmap(&:length)).to eq(Maybe.just 4)
      end
    end

    describe :into do
      it 'calls block with contents of Maybe, or returns nothing if empty' do
        expect(Maybe.just('abcd').into {
          |x| Maybe.just(x.length)
        }).to eq(Maybe.just 4)
      end
    end

    describe :check do
      it 'returns false if Nothing, or passes contents to block (expected to return boolean)' do
        expect(Maybe.just(1).check { |x| x > 0 }).to be true
        expect(Maybe.just(-1).check { |x| x > 0 }).to be false
        expect(Maybe.nothing.check { |x| x > 0 }).to be false
      end
    end
  end

  describe :rand_in do
    it 'returns a random element in an Enumerable' do
      class DummyEnumerable
        include Enumerable

        def init
        end

        def each
          %w{aaa a aaaaaa}.each { |x|
            yield x.length
          }
        end
      end

      dummy = DummyEnumerable.new
      expect([3, 1, 6]).to include(rand_in dummy)
    end
  end

  describe :rand_between do
    it 'returns a random integer between a and b inclusively' do
      expect(rand_between(0, 10)).to be_between(0, 10)
      expect(rand_between(0, 1)).to be_between(0, 1)
      expect(rand_between(1, 1)).to eq(1)
    end
  end
end


