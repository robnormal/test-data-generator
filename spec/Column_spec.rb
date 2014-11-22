require "rspec"
require_relative "../lib/Column.rb"
require 'set'

module TestDataGenerator
  describe Column do
    table = Table.new('dummy', 10)
    num = Column.new(table, 'age', NumberGenerator.new(min: 18, max: 100))

    it 'has symbol attribute "name"' do
      expect(num.name).to eq(:age)
    end

    it 'has Table attribute "table"' do
      expect(num.table).to eq(table)
    end

    describe 'generate_one' do
      it 'uses given generator to produce one datum' do
        expect(num.generate_one).to be_between(18, 100)
      end
    end

    describe 'current' do
      it 'returns the most recently produced datum' do
        last = num.generate_one
        expect(num.current).to eq(last)
      end
    end
  end

  describe ForeignColumn do
    it 'selects random entries from another column' do
      table1 = Table.new('main', 5, [[:id]])
      table2 = Table.new('other', 5)

      belongs = BelongsToGenerator.new(:main, :id)
      foreign = ForeignColumn.new(table2, :main_id, belongs)
      table2.add foreign

      set1 = Set.new(table1.to_a.map { |x| x.first })
      set2 = Set.new(table2.to_a.map { |x| x.first })

      expect(set2.subset?(set1)).to be true
    end

    it 'respects uniqueness' do
      table1 = Table.new('main', 10, [[:id]])
      table2 = Table.new('other', 10)

      belongs = BelongsToGenerator.new(:main, :id, unique: true)
      foreign = ForeignColumn.new(table2, :main_id, belongs)
      table2.add foreign

      a = table1.to_a.map { |x| x.first}
      b = table2.to_a.map { |x| x.first}
      set1 = Set.new(a)
      set2 = Set.new(b)

      # Only need to check that set1 is contained in set2
      # By previous test, we know set2 is contained in set1
      expect(set1.subset?(set2)).to be true
    end
  end
end

