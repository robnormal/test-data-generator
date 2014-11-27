require "rspec"
require_relative "eventually"
require_relative "../lib/data_generators"
require_relative "../lib/dependency"
require_relative "../lib/columnwise_storage"


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

    it 'raises error if more data is produced than limit set by second argument' do
      str = StringGenerator.new(chars: 'a'..'c', max_length: 1)
      uniq = UniqueByUsedGenerator.new(str, 3)
      expect { uniq.iterate 4 }.to raise_error
    end

    describe :reset! do
      it 'forgets unique values already produced' do
        str = StringGenerator.new(chars: 'a'..'c', max_length: 1)
        uniq = UniqueByUsedGenerator.new(str)
        uniq.iterate(3)
        uniq.reset!
        expect { uniq.iterate 1 }.to_not raise_error
      end
    end

    describe :empty? do
      it 'reports if we have run out of unique values to generate' do
        str = StringGenerator.new(chars: 'a'..'c', max_length: 1)
        uniq = UniqueByUsedGenerator.new(str, 3)

        uniq.iterate(2)
        expect(uniq.empty?).to be false

        uniq.reset!
        uniq.iterate(3)
        expect(uniq.empty?).to be true
      end
    end
  end

  describe UniqueEnumGenerator do
    it 'produces unique values from a given dataset' do
      uniq = UniqueEnumGenerator.new('a'..'c')
      expect(uniq.iterate 3).to contain_exactly('a', 'b', 'c')
    end

    it 'raises error if more data is requested than there are unique elements' do
      uniq = UniqueEnumGenerator.new('a'..'c')
      expect { uniq.iterate 4 }.to raise_error
    end
  end


  describe NullGenerator do
    it 'produces null with the given probability' do
      num = NumberGenerator.new(max: 100)
      null = NullGenerator.new(num, 0.5)

      expect { null.generate }.to eventually be_nil
      expect { null.generate }.to eventually be_truthy
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

  context "BelongsTo" do
    before :example do
      def setup_belongs(data)
        @data = data
        @storage = ColumnwiseStorage.new([:users])
        @foreign = ColumnId.new(:users, :id)
        @belongs = BelongsToGenerator.new(@storage, @foreign)
        @unique = UniqueBelongsToGenerator.new(@storage, @foreign)

        set_data(data)
      end

      def set_data(data)
        @storage.reset!

        data.each do |datum|
          @storage.append_row!(:users, { id: datum })
        end
      end
    end

    describe BelongsToGenerator do
      it 'selects data from a column in a Database' do
        setup_belongs([2,3,4])
        expect { @belongs.generate }.to eventually be 2
      end

      it 'always uses the current data' do
        setup_belongs([1])
        expect(@belongs.generate).to be 1

        set_data([2])
        expect(@belongs.generate).to be 2
      end

      describe :dependencies do
        it 'reports the ColumnId of the column it depends on' do
          setup_belongs([1])

          dep = @belongs.dependencies.first
          expect(dep.table).to eq(:users)
          expect(dep.column).to eq(:id)
        end
      end

      describe :needs do
        it 'returns request for 1 value of column it depends on, if that column is empty' do
          setup_belongs([])

          column, num_needed = @belongs.needs(@storage).first
          expect(num_needed).to be 1
        end

        it 'returns empty Array if column has data' do
          setup_belongs([8])

          expect(@belongs.needs(@storage)).to be_empty
        end
      end
    end

    describe UniqueBelongsToGenerator do
      it 'selects unique data from a column in a Database' do
        setup_belongs([2,3,4,5,6,7])
        expect(@unique.iterate 6).to contain_exactly(2,3,4,5,6,7)
      end

      it "knows when it's empty" do
        setup_belongs([2,3,4,5,6,7])
        @unique.iterate 6
        expect(@unique.empty?).to be true
      end

      it 'stays up-to-date with column data, without reusing old data' do
        setup_belongs([3,4,5])
        @unique.iterate 3

        # new data gets added to column...
        set_data([3,4,5,9])

        expect(@unique.generate).to be 9
      end

      it 'raises error if asked for more data than the column has' do
        setup_belongs([0,1])
        expect { @unique.iterate 3 }.to raise_error
      end
    end
  end
end

