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

module TestDataGenerator
  describe StringGenerator do
    it 'produces strings of length <= "max_length" option, if any' do
      str = StringGenerator.new(max_length: 10)
      str.take(10).each do |x|
        expect(x.length).to be <= 10
      end
    end

    it 'produces strings of length == "length" option, if any' do
      str = StringGenerator.new(length: 2)
      str.take(10).each do |x|
        expect(x.length).to eq(2)
      end
    end

    it 'produces strings of length >= "min_length" option, if any' do
      str = StringGenerator.new(max_length: 5, min_length: 2)
      str.take(10).each do |x|
        expect(x.length).to be >= 2
      end
    end

    it 'uses only characters found in "char" option, if any' do
      str = StringGenerator.new(max_length: 5, chars: ['a', 'b'])
      str.take(10).each do |x|
        expect(x).to match(/^[ab]+$/)
      end
    end
  end

  describe NumberGenerator do
    it 'produces integers <= "max" option' do
      num = NumberGenerator.new(max: 2)
      num.take(10).each do |x|
        expect(x).to be <= 2
      end
    end

    it 'raises ArgumentError if no "max" is given' do
      expect { NumberGenerator.new }.to raise_error(ArgumentError)
    end

    it 'produces integers >= "min" option, if any' do
      num = NumberGenerator.new(min: 3, max: 4)
      num.take(10).each do |x|
        expect(x).to be >= 3
      end
    end

    it 'produces integers >= 0, if no "min" given' do
      num = NumberGenerator.new(max: 2)
      num.take(10).each do |x|
        expect(x).to be >= 0
      end
    end

    it 'TOTEST: produces integers > value in column given by "greater_than" option' do
    end
  end

  describe UniqueGenerator do
    it 'produces unique values from a given generator' do
      str = StringGenerator.new(chars: 'a'..'c', max_length: 1)
      uniq = UniqueGenerator.new(str)
      expect(uniq.take 3).to contain_exactly('a', 'b', 'c')
    end

    it 'raises RangeError if more data is produced than the limit set by "max" option' do
      str = StringGenerator.new(chars: 'a'..'c', max_length: 1)
      uniq = UniqueGenerator.new(str, max: 3)
      expect { uniq.take 4 }.to raise_error(RangeError)
    end
  end

  describe EnumGenerator do
    it 'selects random elements from a given enumerable' do
      enum = EnumGenerator.new(['Alice', 'Bob', 'Eve'])
      enum.take(10).each do |x|
        expect(['Alice', 'Bob', 'Eve']).to include(x)
      end
    end

    it 'produces unique elements if "unique" option is true' do
      enum = EnumGenerator.new([1,1,1,2,3], unique: true)
      expect(enum.take 3).to contain_exactly(1, 2, 3)
    end
  end

end

