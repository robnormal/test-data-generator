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
      @columns.keys
    end

    def column(column_name)
      @columns[column_name]
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
      @columns.values.map(&:dependencies).flatten.uniq
    end

    def needs(column_data)
      @columns.map { |_, c| c.needs(column_data) }.flatten(1)
    end

    def dependencies_as_edges
      @columns.map { |_, c|
        c.dependency_edges(@name)
      }.flatten
    end


    private


    def add_raw!(column)
      @columns[column.name] = column
      @column_names << column.name
    end

    def generate_column!(column, db)
      @data[column] << @columns[column].generate(db)
    end

  end
end

