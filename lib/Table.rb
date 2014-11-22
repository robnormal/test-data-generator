require_relative('Generator.rb')
require_relative('Column.rb')

module TestDataGenerator
  class Table
    include Enumerable

    attr_reader :name, :rows_produced, :num_rows

    def initialize(name, num_rows, col_config = [])
      @name          = name.to_sym
      @num_rows      = num_rows
      @rows_produced = 0
      @columns       = {}

      # register this table with the class
      @@tables[@name] = self

      col_config.each do |cfg|
        col_name, type, args, options = *cfg

        add_from_spec(col_name, type, args || [], options || {})
      end
    end

    # add a Column to the table
    def add(column)
      @columns[column.name] = column

      if column.is_a? ForeignColumn
        @@need_all << [column.foreign_table, column.foreign_column]
      end
    end

    # add a Column using Column.from_spec
    def add_from_spec(column_name, type, args = [], options = {})
      add Column.from_spec(self, column_name, type, args, options)
    end

    def column(column_name)
      @columns[column_name]
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

    # only use for cached columns
    def all(column_name)
      @columns[column_name].all
    end

    def need_all?(column)
      @@need_all.include? [@name, column.name]
    end

    # shortcut method
    def self.current(table_name, column_name)
      @@tables[table_name].current column_name
    end

    # shortcut method
    def self.all(table_name, column_name)
      @@tables[table_name].all column_name
    end

    # shortcut method
    def self.table(table_name)
      @@tables[table_name]
    end

    private
    @@tables = {}
    @@need_all = []

    @columns
    @num_rows
    @rows_produced
  end
end

