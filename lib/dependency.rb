module TestDataGenerator
  class ColumnId
    attr_reader :table, :column

    def initialize(table, column)
      @table = table
      @column = column
    end

    def ==(c)
      c.table == self.table && c.column == self.column
    end
  end
end
