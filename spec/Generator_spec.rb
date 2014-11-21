require "rspec"
require_relative "../lib/Generator.rb"

describe "Generator" do
  describe :hash_map do
    it 'maps a Hash to a Hash' do
      words = { first: 'apple', second: 'bob', third: '' }
      lengths = hash_map(words) { |key, val|
        [val, val.length]
      }

      expect(lengths['apple']).to eq(5)
    end
  end

  describe :iterate do
    it 'runs a block n times, and returns outputs in an array' do
      letters = %w{a b c}
      popped = iterate(3) { letters.pop() }
      expect(popped).to match_array(%w{c b a})
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
      expect(rand_between(0, 10)).to be_between(0, 10).inclusive
      expect(rand_between(0, 1)).to be_between(0, 1).inclusive
      expect(rand_between(1, 1)).to eq(1)
    end
  end

end

