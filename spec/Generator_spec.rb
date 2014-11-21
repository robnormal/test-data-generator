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

  describe TestDataGenerator::StringGenerator do
    it 'produces strings of length <= "max_length" option, if any' do
      str = TestDataGenerator::StringGenerator.new(max_length: 10)
      str.take(10).each do |x|
        expect(x.length).to be <= 10
      end
    end

    it 'produces strings of length == "length" option, if any' do
      str = TestDataGenerator::StringGenerator.new(length: 2)
      str.take(10).each do |x|
        expect(x.length).to eq(2)
      end
    end

    it 'produces strings of length >= "min_length" option, if any' do
      str = TestDataGenerator::StringGenerator.new(max_length: 5, min_length: 2)
      str.take(10).each do |x|
        expect(x.length).to be >= 2
      end
    end

    it 'uses only characters found in "char" option, if any' do
      str = TestDataGenerator::StringGenerator.new(max_length: 5, chars: ['a', 'b'])
      str.take(10).each do |x|
        expect(x).to match(/^[ab]+$/)
      end
    end
  end

  describe TestDataGenerator::UniqueGenerator do
    it 'produces unique values from a given generator' do
      str = TestDataGenerator::StringGenerator.new(chars: 'a'..'c', max_length: 1)
      uniq = TestDataGenerator::UniqueGenerator.new(str)
      expect(uniq.take 3).to contain_exactly('a', 'b', 'c')
    end

    it 'raises RangeError if more data is produced than the limit set by "max" option' do
      str = TestDataGenerator::StringGenerator.new(chars: 'a'..'c', max_length: 1)
      uniq = TestDataGenerator::UniqueGenerator.new(str, max: 3)
      expect { uniq.take 4 }.to raise_error(RangeError)
    end
  end
end

