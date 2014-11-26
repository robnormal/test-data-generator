module TestDataGenerator
  # For querying data in specific columns, without
  # allowing access to the full data structure
  class ColumnData
    def initialize(data)
      @data = data
    end

    def data_for(column_id)
      raise(ArgumentError, 'No such column') if @data[column_id.table].nil?
      @data[column_id.table][column_id.column]
    end
  end
end
