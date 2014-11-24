require_relative('data_generators.rb')
require_relative('Column.rb')

module TestDataGenerator
  class Table
    include Generator

    attr_reader :name

    def initialize(name, col_config = [])
      @name          = name.to_sym
      @columns       = {}

      col_config.each do |cfg|
        col_name, type, args, options = *cfg

        add_from_spec!(col_name, type, args || [], options || {})
      end
    end

    def generate
      @columns.values.map &:generate
    end

    # add a Column to the table
    def add!(column)
      @columns[column.name] = column
    end

    # add a Column using Column.from_spec
    def add_from_spec!(column_name, type, args = [], options = {})
      add! Column.from_spec(column_name, type, args, options)
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

    # Determine which Tables need to produce more rows before we can proceed,
    # and how many rows we need
    def needs(data)
    end
  end
end

