require "rspec"
require_relative "../lib/Column.rb"

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
end

