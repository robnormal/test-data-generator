require "rspec"
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
      @table = Table.new(:table)
    end
    
    it 'has String attribute "name"' do
      expect(Database.new('dummy', {@table => 1}).name).to eq('dummy')
    end

    it 'has Hash attribute "data"' do
      expect(Database.new('dummy', {@table => 1}).data).to be_a(Hash)
    end

    describe :initialize do
      it 'accepts a Hash, specifying tables in the DB and how many rows to generate' do
        table1 = Table.new(:table1)
        table2 = Table.new(:table2)
        col1 = Column.new(:col1, CountGenerator.new)
        col2 = Column.new(:col2, CountGenerator.new)

        table1.add! col1
        table2.add! col2

        db = Database.new('db', { table1 => 3, table2 => 4 })
        db.generate_all!

        expect(db.data[:table1]).to be_a(Array)
        expect(db.data[:table1]).to contain_exactly(1, 2, 3)
      end
    end
  end
end

