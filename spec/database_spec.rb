require "rspec"
require_relative "eventually"
require_relative "../test-data-generator"

module TestDataGenerator
  # toy Generator class
  class CountGenerator
    include Generator
    @current

    def initialize
      @current = 0
    end

    def generate(_ = nil)
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

      @db = Database.new({ @table1 => 3, @table2 => 5 })
    end

    describe :generate! do
      it "generates one row for a table of it's choosing" do
        @db.generate!

        # should have on row total in @db
        expect(@db.height(:table1) + @db.height(:table2)).to eq(1)
      end
    end

    describe :generate_all! do
      it 'generates all rows for all tables' do
        @db.generate_all!
        expect(@db.height(:table1)).to eq(3)
      end
    end

    describe :add_table! do
      it 'adds a table to the database' do
        db = Database.new
        db.add_table!(@table1, 3)

        expect { db.height :table1 }.not_to raise_error

        db.generate_all!
        expect(db.height :table1).to eq(3)
      end
    end

    describe :retrieve_by_id do
      it 'retrieves data by ColumnId' do
        @db.generate_all!
        id = ColumnId.new(:table1, :col1)

        col_data = @db.retrieve_by_id(id)
        expect(col_data.length).to eq(3)
      end
    end

    describe :table_names do
      it 'returns the names of the tables' do
        expect(@db.table_names).to contain_exactly(:table1, :table2)
      end
    end

    describe :column_names do
      it 'returns the names of the columns in table' do
        expect(@db.column_names(:table2)).to contain_exactly(:col2)
      end
    end

    it 'fills data as needed by dependent columns' do
      col = ColumnId.new(:table1, :col1)
      gen = BelongsToGenerator.new(col)
      @table2.add!(Column.new(:depends, gen))

      # if it tries to generate a row for table2, @db will
      # have to generate a row for table1 first; thus,
      # we'll have one row in each
      expect { 
        @db.reset!
        @db.generate!
        col1_height = @db.retrieve(:table1, :col1).length
        col2_height = @db.retrieve(:table2, :col2).length
        [ col1_height, col2_height ]
      }.to eventually be == [1, 1]
    end

    it 'resolves complex dependencies' do
      col1 = ColumnId.new(:table1, :col1)
      gen1 = BelongsToGenerator.new(col1)

      col2 = ColumnId.new(:table2, :col2)
      gen2 = BelongsToGenerator.new(col2)

      @table1.add!(Column.new(:depends, gen2))
      @table2.add!(Column.new(:depends, gen1))

      # if it tries to generate a row for table2, @db will
      # have to generate a row for table1 first; thus,
      # we'll have one row in each
      expect { 
        @db.reset!
        @db.generate!
        col1_height = @db.retrieve(:table1, :col1).length
        col2_height = @db.retrieve(:table2, :col2).length
        [ col1_height, col2_height ]
      }.to eventually be == [1, 1]
    end

    it 'raises an error for circular dependencies' do
    end

    describe :reset! do
      it 'deletes existing data' do
        3.times { @db.generate! }
        @db.reset!

        expect(@db.retrieve(:table2, :col2)).to eq([])
      end
    end

    describe :each_row do
      it 'yields data from category as rows, in order appended' do
        @db.generate_all!

        table1 = []
        @db.each_row(:table1) do |row|
          table1 << row
        end

        expect(table1.length).to eq(3)
        expect(table1[1][:col1]).to eq(2)
      end
    end

    describe :dump do
      it 'yields all rows from all categories, in a Hash' do
        @db.generate_all!

        data = @db.dump

        expect(data[:table1].length).to eq(3)
        expect(data[:table1][1][:col1]).to eq(2)
        expect(data[:table2].length).to eq(5)
        expect(data[:table2][3][:col2]).to eq(4)
      end
    end

  end
end

