require_relative('data_generators')
require_relative('column')

module TestDataGenerator
  class Table
    include Generator

    attr_reader :name, :column_names, :height

    def initialize(name, columns = [])
      @name         = name.to_sym
      @column_hash  = {}
      @columns      = []
      @column_names = []

      columns.each do |c| add_raw!(c) end
      reset!
    end

    def fulfill_need!(column, num, db)
      num.times do
        generate_column!(column, db)
      end
    end

    # add a Column to the table
    def add!(column)
      add_raw!(column)
      @data[column.name] = []
    end

    def generate!(db)
      # generate needed data
      needs(db).each do |source, num|
        db.fulfill_need!(source, num, name)
      end

      @column_names.each do |c|
        # don't generate data for this column if we already have what we need
        if @data[c].length <= @height
          generate_column!(c, db)
        end
      end

      @height += 1

      row(@height - 1)
    end

    def each
      @height.times do |i|
        yield row(i)
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
      @column_names
    end

    def column(column_name)
      @column_hash[column_name]
    end

    def retrieve(col_name)
      @data[col_name]
    end

    def row(num)
      Hash[
        @column_names.map { |c| [c, retrieve(c)[num]] }
      ]
    end

    def dependencies
      list_bind(@columns, &:dependencies).uniq
    end

    def needs(db)
      list_bind(@columns) { |c| c.needs(db) }
    end

    def dependencies_as_edges
      list_bind(@columns) { |c|
        column_dependency_edges(c)
      }
    end


    private

    def column_dependency_edges(c)
      my_id = ColumnId.new(name, c.name)

      c.dependencies.map { |col_id|
        GraphEdge.new(my_id, col_id)
      }
    end

    def add_raw!(column)
      @columns << column
      @column_names << column.name
      @column_hash[column.name] = column
    end

    def generate_column!(col, db)
      @data[col] << column(col).generate(db)
    end

  end
end

