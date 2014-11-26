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

  describe DependencyEdge do
    before :context do
      @col1 = ColumnId.new(:a, :b)
      @col2 = ColumnId.new(:c, :d)

      @dep = DependencyEdge.new(@col1, @col2)
    end

    it 'has a ColumnId attribute called "from"' do
      expect(@dep.from).to be @col1
    end

    it 'has a ColumnId attribute called "to"' do
      expect(@dep.to).to be @col2
    end
  end
end

