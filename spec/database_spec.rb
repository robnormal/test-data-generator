require "rspec"
require_relative "eventually"
require_relative "../lib/database"
require_relative "../lib/columnwise_storage"

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

      @db = Database.new('db', [@table1, @table2])
    end
    
    it 'has String attribute "name"' do
      expect(@db.name).to eq('db')
    end

    it 'has Array attribute "table_names"' do
      expect(@db.table_names).to be_a(Array)
    end

    describe :generate_for do
      it 'generates a row for the given table' do
        expect(@db.generate_for(:table1)).to eq({ col1: 1 })
      end
    end

    describe :needs_for do
      it 'returns columns that need more data before we can generate, and by how much' do
        storage = double(ColumnwiseStorage)
        allow(storage).to receive(:retrieve_by_id) { [] }

        foreign = ColumnId.new(:table1, :col1)
        belongs = BelongsToGenerator.new(storage, foreign)
        @table2.add!(Column.new(:belonger, belongs))

        expect(@db.needs_for(:table2, storage)).to eq( [[foreign, 1]] )
      end
    end

  end
end

