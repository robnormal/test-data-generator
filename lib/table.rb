require_relative('data_generators')
require_relative('column')

module TestDataGenerator
  class Table
    include Generator

    attr_reader :name, :column_names, :height

    def initialize(name, columns = [])
      @name          = name.to_sym
      @columns       = {}
      @column_names  = []

      columns.each do |c| add_raw!(c) end
      reset!
    end

    def fulfill_need!(column, num)
      1.upto(num).each {
        @data[column] << @columns[column].generate
      }
    end

    # add a Column to the table
    def add!(column)
      add_raw!(column)
      @data[column.name] = []
    end

    # add a Column using Column.from_spec
    def add_from_spec!(column_name, type, args = [], options = {})
      add! Column.from_spec(column_name, type, args, options)
    end

    def generate!(db)
      row = {}
      @column_names.each do |c|
        # don't generate data for this column if we already have what we need
        if @data[c].length <= @height
          row[c] = @columns[c].generate(db)
          @data[c] << row[c]
        end
      end

      @height += 1
      row
    end

    def offload!
      @height.times do
        row = {}
        @column_names.each do |col|
          row[col] = @data[col].shift
        end

        yield row
      end
    end

    def reset!
      @height = 0
      @data = {}

      @column_names.each do |c|
        @data[c] = []
      end
    end

    def columns
      @columns.keys
    end

    def column(column_name)
      @columns[column_name]
    end

    def retrieve(col_name)
      @data[col_name]
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


    private


    def add_raw!(column)
      @columns[column.name] = column
      @column_names << column.name
    end

  end
end

