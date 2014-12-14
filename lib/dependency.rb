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

    def to_a
      [@table, @column]
    end

    def to_s
      @table.to_s + '.' + @column.to_s
    end
  end
end
