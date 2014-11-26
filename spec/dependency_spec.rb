require "rspec"
require_relative "../lib/dependency"

module TestDataGenerator
  describe ColumnId do
    it 'has a Symbol attribute called "table"' do
      col = ColumnId.new(:a, :b)
      expect(col.table).to be :a
    end

    it 'has a Symbol attribute called "column"' do
      col = ColumnId.new(:a, :b)
      expect(col.column).to be :b
    end
  end
end

