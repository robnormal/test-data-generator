require "rspec"
require_relative "eventually"
require_relative "../lib/database"
require_relative "../lib/column_data"

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

      @db = Database.new('db', { @table1 => 3, @table2 => 4 })
    end
    
    it 'has String attribute "name"' do
      expect(@db.name).to eq('db')
    end

    it 'has Hash attribute "data"' do
      expect(@db.data).to be_a(Hash)
    end

    describe :initialize do
      describe 'accepts a Hash of tables => # of rows, then' do
        describe :generate_all! do
          it 'generates all rows requested' do
            @db.generate_all!

            expect(@db.data[:table1][:col1]).to contain_exactly(1, 2, 3)
          end
        end
      end
    end

    describe :reset do
      it 'discards all generated data' do
        @db.generate_all!
        @db.reset!
        expect(@db.data[:table1][:col1]).to be_empty
        expect(@db.data[:table2][:col2]).to be_empty
      end
    end

    # Database must produce BelongsToGenerator for you...
    describe :create_belongs_to do
      it 'returns a new Column that BelongsTo given column' do
        belongs = @db.create_belongs_to(:belongs, :table1, :col1)
      end
    end

    it 'fills data as needed by dependent columns' do
      belongs = @db.create_belongs_to(:belongs, :table1, :col1)
      @table2.add! belongs
        
      @db.generate!

      expect { 
        @db.reset!
        @db.generate!
        [@db.data[:table1].length, @db.data[:table2].length]
      }.to eventually be == [1, 1]
    end
  end
end

