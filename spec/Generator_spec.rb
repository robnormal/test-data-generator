require "rspec"
require_relative "../lib/Generator.rb"

describe "Generator" do
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

    it 'produces integers >= current value in "greater_than" column' do
      table = Table.new('numgen', 10)
      col = Column.new(table, 'num', NumberGenerator.new(max: 3))
      table.add(col)

      greater = NumberGenerator.new(max: 3, greater_than: [:numgen, :num])

      n = col.generate_one
      expect(greater.take(10).all? { |x| x <= 3 && x >= n }).to be true
    end
  end

  describe DateTimeGenerator do
    it 'creates random timestamp, with NumberGenerator options' do
      date = DateTimeGenerator.new(min: 100, max: 103)
      date.take(10).each do |x|
        expect(x).to be_between(100, 103)
      end
    end

    it 'uses Time.now() as default for "max"' do
      date = DateTimeGenerator.new
      now = Time.now().to_i
      date.take(10).each do |x|
        expect(x).to be <= now
      end
    end
  end

  describe UrlGenerator do
    it 'creates random, valid URLs' do
      require 'uri'

      url = UrlGenerator.new
      url.take(10).each do |x|
        expect(x).to match(/\A#{URI::regexp(['http', 'https'])}\z/)
      end
    end
  end

  describe ForgeryGenerator do
    describe :initialize do
      it 'gets the specified Forgery object, and calls given method with given arguments' do
        forge = ForgeryGenerator.new(:email, :address)

        # crude email regex
        expect(forge.first).to match(/^[^@]+@[^@.]+\.[^@]+$/)
      end
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
      expect { enum.take 4 }.to raise_error(IndexError)
    end
  end

  describe UniqueGenerator do
    it 'produces unique values from a given generator' do
      str = StringGenerator.new(chars: 'a'..'c', max_length: 1)
      uniq = UniqueGenerator.new(str)
      expect(uniq.take 3).to contain_exactly('a', 'b', 'c')
    end

    it 'raises IndexError if more data is produced than the limit set by "max" option' do
      str = StringGenerator.new(chars: 'a'..'c', max_length: 1)
      uniq = UniqueGenerator.new(str, max: 3)
      expect { uniq.take 4 }.to raise_error(IndexError)
    end
  end

  describe NullGenerator do
    it 'produces null with the given probability' do
      num = NumberGenerator.new(max: 100)
      null = NullGenerator.new(num, 0.5)

      # test that nil is eventually produced
      tries = 0
      while tries < 100000
        if null.first.nil?
          break
        end
        tries += 1
      end

      expect(tries).to be < 100000

      # test that something *other than* nil is eventually produced
      tries = 0
      while tries < 100000
        unless null.first.nil?
          break
        end
        tries += 1
      end

      expect(tries).to be < 100000
    end
  end

end

