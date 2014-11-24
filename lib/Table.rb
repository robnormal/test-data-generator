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
      @columns.map(&:dependencies).flatten
    end

    def dependencies_as_edges
      @columns.map { |c|
        c.dependencies.map { |d| [[@name, c.name], [d.table, d.column]] }
      }.flatten
    end

    # Determine which Tables need to produce more rows before we can proceed,
    # and how many rows we need
    def needs(data)
    end

  end
end

