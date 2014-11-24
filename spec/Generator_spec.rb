require "rspec"
require_relative "../lib/data_generators"
require_relative "../lib/Table"

module TestDataGenerator
  describe StringGenerator do
    it 'produces strings of length <= "max_length" option, if any' do
      str = StringGenerator.new(max_length: 10)
      str.iterate(10).each do |x|
        expect(x.length).to be <= 10
      end
    end

    it 'produces strings of length == "length" option, if any' do
      str = StringGenerator.new(length: 2)
      str.iterate(10).each do |x|
        expect(x.length).to eq(2)
      end
    end

    it 'produces strings of length >= "min_length" option, if any' do
      str = StringGenerator.new(max_length: 5, min_length: 2)
      str.iterate(10).each do |x|
        expect(x.length).to be >= 2
      end
    end

    it 'uses only characters found in "char" option, if any' do
      str = StringGenerator.new(max_length: 5, chars: ['a', 'b'])
      str.iterate(10).each do |x|
        expect(x).to match(/^[ab]+$/)
      end
    end
  end

  describe NumberGenerator do
    it 'produces integers <= "max" option' do
      num = NumberGenerator.new(max: 2)
      num.iterate(10).each do |x|
        expect(x).to be <= 2
      end
    end

    it 'raises ArgumentError if no "max" is given' do
      expect { NumberGenerator.new }.to raise_error(ArgumentError)
    end

    it 'produces integers >= "min" option, if any' do
      num = NumberGenerator.new(min: 3, max: 4)
      num.iterate(10).each do |x|
        expect(x).to be >= 3
      end
    end

    it 'produces integers >= 0, if no "min" given' do
      num = NumberGenerator.new(max: 2)
      num.iterate(10).each do |x|
        expect(x).to be >= 0
      end
    end

    it 'produces integers >= current last value in "greater_than" list' do
      val_list = [0]
      greater = NumberGenerator.new(max: 3, greater_than: val_list)

      expect(greater.iterate(10).all? { |x| x >= 0 && x <= 3 }).to be true
      val_list << 2
      expect(greater.iterate(10).all? { |x| x >= 2 && x <= 3 }).to be true
    end
  end

  describe DateTimeGenerator do
    it 'creates random timestamp, with NumberGenerator options' do
      date = DateTimeGenerator.new(min: 100, max: 103)
      date.iterate(10).each do |x|
        expect(x).to be_between(100, 103)
      end
    end

    it 'uses Time.now() as default for "max"' do
      date = DateTimeGenerator.new
      now = Time.now().to_i
      date.iterate(10).each do |x|
        expect(x).to be <= now
      end
    end
  end

  describe UrlGenerator do
    it 'creates random, valid URLs' do
      require 'uri'

      url = UrlGenerator.new
      url.iterate(10).each do |x|
        expect(x).to match(/\A#{URI::regexp(['http', 'https'])}\z/)
      end
    end
  end

  describe ForgeryGenerator do
    describe :initialize do
      it 'gets the specified Forgery object, and calls given method with given arguments' do
        forge = ForgeryGenerator.new(:email, :address)

        # crude email regex
        expect(forge.generate).to match(/^[^@]+@[^@.]+\.[^@]+$/)
      end
    end
  end

  describe EnumGenerator do
    it 'selects random elements from a given enumerable' do
      enum = EnumGenerator.new(['Alice', 'Bob', 'Eve'])
      enum.iterate(10).each do |x|
        expect(['Alice', 'Bob', 'Eve']).to include(x)
      end
    end
  end

  describe UniqueByUsedGenerator do
    it 'produces unique values from a given generator' do
      str = StringGenerator.new(chars: 'a'..'c', max_length: 1)
      uniq = UniqueByUsedGenerator.new(str)
      expect(uniq.iterate 3).to contain_exactly('a', 'b', 'c')
    end

    it 'raises IndexError if more data is produced than limit set by second argument' do
      str = StringGenerator.new(chars: 'a'..'c', max_length: 1)
      uniq = UniqueByUsedGenerator.new(str, 3)
      expect { uniq.iterate 4 }.to raise_error
    end
  end

  describe NullGenerator do
    it 'produces null with the given probability' do
      num = NumberGenerator.new(max: 100)
      null = NullGenerator.new(num, 0.5)

      # test that nil is eventually produced
      tries = 0
      while tries < 100000
        if null.generate.nil?
          break
        end
        tries += 1
      end

      expect(tries).to be < 100000

      # test that something *other than* nil is eventually produced
      tries = 0
      while tries < 100000
        unless null.generate.nil?
          break
        end
        tries += 1
      end

      expect(tries).to be < 100000
    end
  end

  describe Generator do
    describe :to_unique do
      it 'returns a unique version of this generator' do
        enum = EnumGenerator.new([1,1,1,2,3]).to_unique
        expect(enum.iterate 3).to contain_exactly(1, 2, 3)
        expect { enum.iterate 4 }.to raise_error
      end
    end
  end

end

