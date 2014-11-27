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
        expect(Maybe.nothing).not_to eq(Maybe.just(8))
        expect(Maybe.just(8)).not_to eq(Maybe.nothing)
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

  describe :hash_subset do
    it 'copies only specified keys to a new hash' do
      h = { a: 3, b: 2 }

      expect(hash_subset(h, [:a]).length).to be 1
      expect(hash_subset(h, [:a])[:a]).to be 3
    end
  end

  describe :fmap do
    it 'maps a block over a Hash in the natural way' do
      h = { a: 'aaa', b: 'bbbb' }
      len = fmap(h, &:length)

      expect(len[:a]).to be 3
      expect(len[:b]).to be 4
    end

    it 'maps other things using &:map' do
      len = fmap(['aa', 'bbbb'], &:length)

      expect(len[0]).to be 2
      expect(len[1]).to be 4
    end
  end

  describe :fmap_with_keys do
    it 'treats Hashes like fmap, but passes the key as well as the value to the block' do
      h = { a: 3, b: 4 }
      repeats = fmap_with_keys(h) { |k, v|
        v.downto(1).inject('') { |s| s + k.to_s }
      }

      expect(repeats[:a]).to eq('aaa')
      expect(repeats[:b]).to eq('bbbb')
    end
  end
end


