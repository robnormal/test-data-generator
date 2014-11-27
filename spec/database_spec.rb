require "rspec"
require_relative "eventually"
require_relative "../lib/dependency"
require_relative "../lib/database"

module TestDataGenerator
  # toy Generator class
  class CountGenerator
    include Generator
    @current

    def initialize
      @current = 0
    end

    def generate
      @current += 1
    end
  end

  describe Database do
    before :example do
      @table1 = Table.new(:table1)
      @table2 = Table.new(:table2)
      @col1 = Column.new(:col1, CountGenerator.new)
      @col2 = Column.new(:col2, CountGenerator.new)

      @table1.add! @col1
      @table2.add! @col2

      @storage = Database.new({ @table1 => 3, @table2 => 5 })
    end

    describe :generate! do
      it "generates one row for a table of it's choosing" do
        @storage.generate!

        # should have on row total in @storage
        expect(@storage.height(:table1) + @storage.height(:table2)).to eq(1)
      end
    end

    describe :generate_all! do
      it 'generates all rows for all tables' do
        @storage.generate_all!
        expect(@storage.height(:table1)).to eq(3)
      end
    end

    describe :add_table! do
      it 'adds a table to the database' do
        storage = Database.new
        storage.add_table!(@table1, 3)

        expect { storage.height :table1 }.not_to raise_error

        storage.generate_all!
        expect(storage.height :table1).to eq(3)
      end
    end

    describe :retrieve_by_id do
      it 'retrieves data by ColumnId' do
        @storage.generate_all!
        id = ColumnId.new(:table1, :col1)

        col_data = @storage.retrieve_by_id(id)
        expect(col_data.length).to eq(3)
      end
    end

    it 'fills data as needed by dependent columns' do
      col = ColumnId.new(:table1, :col1)
      gen = BelongsToGenerator.new(@storage, col)
      @table2.add!(Column.new(:depends, gen))

      # if it tries to generate a row for table2, @db will
      # have to generate a row for table1 first; thus,
      # we'll have one row in each
      expect { 
        @storage.reset!
        @storage.generate!
        col1_height = @storage.retrieve(:table1, :col1).length
        col2_height = @storage.retrieve(:table2, :col2).length
        [ col1_height, col2_height ]
      }.to eventually be == [1, 1]
    end

    describe :reset! do
      it 'deletes existing data' do
        3.times { @storage.generate! }
        @storage.reset!

        expect(@storage.retrieve(:table2, :col2)).to eq([])
      end
    end

    describe :offload! do
      it 'yields data from category as rows, in order appended, then deletes that data' do
        @storage.generate_all!

        table1 = []
        @storage.offload!(:table1) do |row|
          table1 << row
        end

        expect(table1.length).to eq(3)
        expect(table1).to contain_exactly([1], [2], [3])
      end
    end

    describe :offload_all! do
      it 'yields all rows from all categories, in a Hash' do
        @storage.generate_all!

        data = @storage.offload_all!

        expect(data[:table1].length).to eq(3)
        expect(data[:table1]).to contain_exactly([1], [2], [3])
        expect(data[:table2].length).to eq(5)
        expect(data[:table2]).to contain_exactly([1], [2], [3], [4], [5])
      end
    end

  end
end

