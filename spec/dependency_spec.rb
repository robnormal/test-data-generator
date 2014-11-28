require "rspec"
require_relative "../lib/dependency"

module TestDataGenerator
  describe ColumnId do
    before :context do
      @col = ColumnId.new(:a, :b)
    end

    it 'has a Symbol attribute called "table"' do
      expect(@col.table).to be :a
    end

    it 'has a Symbol attribute called "column"' do
      expect(@col.column).to be :b
    end
  end
end

