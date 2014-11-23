require_relative('data_generators.rb')
require_relative('Column.rb')

module TestDataGenerator
  class Table
    include Generator

    attr_reader :name, :rows_produced, :num_rows

    def initialize(name, num_rows, col_config = [])
      @name          = name.to_sym
      @num_rows      = num_rows
      @rows_produced = 0
      @columns       = {}

      col_config.each do |cfg|
        col_name, type, args, options = *cfg

        add_from_spec!(col_name, type, args || [], options || {})
      end
    end

    # add a Column to the table
    def add!(column)
      @columns[column.name] = column
    end

    # add a Column using Column.from_spec
    def add_from_spec!(column_name, type, args = [], options = {})
      add! Column.from_spec(self, column_name, type, args, options)
    end

    def column(column_name)
      @columns[column_name]
    end

    def dependencies
      dependencies = []
      @columns.each do |column|
        if column.is_a? DependentColumnStub
          # turn dependencies into edges - a pair like [[table, column], [table, column]]
          dependencies += column.dependencies.map { |d|
            [[@name, column.name], d]
          }
        end
      end
    end

    def current(column_name)
      @columns[column_name].current
    end

    def row
      if @rows_produced >= @num_rows
        raise(IndexError, 'No more rows available')
      end

      @rows_produced += 1
      @columns.values.map &:current
    end

    def each
      @num_rows.times { yield row }
    end

    # reset @rows_produced count
    def clear
      @rows_produced = 0
    end

    def all(column_name)
      @columns[column_name].to_a
    end

    private
    @columns
    @num_rows
    @rows_produced
  end
end

