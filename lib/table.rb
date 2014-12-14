require_relative('data_generators')
require_relative('column')

module TestDataGenerator
  class Table
    include Generator

    attr_reader :name, :column_names

    def initialize(name, columns = [])
      @name          = name.to_sym
      @columns       = {}
      @column_names  = []

      columns.each do |c| add!(c) end
    end

    def generate(column_data)
      fmap(@columns) { |c| c.generate column_data }
    end

    def fulfill_need(column, num)
      1.upto(num).map {
        @columns[column].generate
      }
    end

    # add a Column to the table
    def add!(column)
      @columns[column.name] = column
      @column_names << column.name
    end

    # add a Column using Column.from_spec
    def add_from_spec!(column_name, type, args = [], options = {})
      add! Column.from_spec(column_name, type, args, options)
    end

    def column(column_name)
      @columns[column_name]
    end

    def dependencies
      @columns.values.map(&:dependencies).flatten.uniq
    end

    def needs(column_data)
      @columns.values.inject([]) { |memo, c|
        memo + (c.needs column_data)
      }
    end

    def dependencies_as_edges
      @columns.values.map { |c|
        c.dependencies.map { |col_id|
          GraphEdge.new(ColumnId.new(@name, c.name), col_id)
        }
      }.flatten
    end

  end
end

